using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using FeedbackEngine_WebJobs.Models;
using Microsoft.WindowsAzure.Storage.Table;
using Microsoft.Azure.WebJobs.Host;

using System.ServiceModel.Syndication;
using System.ServiceModel;
using System.Xml;

namespace FeedbackEngine_WebJobs
{
    public class Questions
    {
        private Dictionary<string, Dictionary<string, string>> mFeedSources = new Dictionary<string,Dictionary<string,string>>()
        {
            {"StackOverflow", new Dictionary<string, string>()
                {   
                    {"Mobile","http://stackoverflow.com/feeds/tag/azure-mobile-services"},
                    {"Web","http://stackoverflow.com/feeds/tag/azure-web-sites"}
                }
            }
        };

        // Post /Questions/AddQuestion will add question to NewQuestions Queue
        public void AddQuestion([WebHookTrigger] Question inQ, [Queue("SaveQuestions")] out Question outQ)
        {
            outQ = inQ;
        }
        
        // On Timer, grab items from RSS Feed
        public void RSSFeedProcessor([TimerTrigger("0 */5 * * * *", RunOnStartup=true)] TimerInfo timer, [Queue("SaveQuestions")]  ICollector<Question> outQ, TraceWriter log)
        {
            log.Verbose("RSS Feed Processor started");
            Console.WriteLine("RSS Feed Processor started");
            foreach (var feeds in mFeedSources)
            {
                switch(feeds.Key){
                    case "StackOverflow":
                        foreach (var feed in feeds.Value)
                        {
                            XmlReader reader = XmlReader.Create(feed.Value);
                            SyndicationFeed rss = SyndicationFeed.Load(reader);
                            reader.Close();
                            foreach (SyndicationItem item in rss.Items)
                            {
                                outQ.Add(ProcessStackOverflowEntry(item, feed.Key));
                            }
                        }
                        break;
                    default:
                        log.Warning(String.Format("Couldn't recognize feed format: {0}", feeds.Key),"RSSFeedProcessor");
                        break;
                }
            }
        }

        public void SaveQuestion([QueueTrigger("SaveQuestions")] Question q, [Table("Questions")] CloudTable questionsTable, [Queue("SlackMessage")] ICollector<Message> messageQ, [Table("People")] CloudTable peopleTable)
        {
            // Upsert into Table Storage
            TableOperation retrieveOperation = TableOperation.Retrieve<Question>(q.PartitionKey, q.RowKey);
            TableResult retrievedResult = questionsTable.Execute(retrieveOperation);
            Question updateEntity = (Question)retrievedResult.Result;

            // Update existing item if it has new content
            if (updateEntity != null && updateEntity.UpdatedOn != q.UpdatedOn)
            {
                // Fields requiring update
                updateEntity.UpdatedOn = q.UpdatedOn;

                TableOperation updateOperation = TableOperation.Replace(updateEntity);
                questionsTable.Execute(updateOperation);
            }
            // Process new item
            else
            {
                People p = AssignOwner(q, peopleTable);
                if (p != null)
                {
                    q.AssignedTo = p.Email;
                }

                TableOperation insertOperation = TableOperation.Insert(q);
                questionsTable.Execute(insertOperation);

                // Add message for the default channel
                messageQ.Add(new Message()
                {
                    to = null,
                    contents = String.Format("[{0}][{1}][{2}]<{4}|{3}>", q.ShortId, (p!= null && p.SlackNotify) ? String.Format("@{0}", p.Slack) : q.AssignedTo, q.Category, q.Title, q.Url)
                });

                // If they've opted into Slack Notify, send them a message
                if(p!=null && p.SlackNotify)
                {
                    messageQ.Add(new Message()
                    {
                        to = String.Format("@{0}", p.Slack),
                        contents = String.Format("New message assigned to you! [{0}][{1}]<{3}|{2}>", q.ShortId, q.Category, q.Title, q.Url)
                    });
                }
            }
        }

        // Begin private methods

        private People AssignOwner(Question q, CloudTable table)
        {
            // Grab a random person from the list of people who match that category.
            TableQuery<People> query = new TableQuery<People>();
            var results = table.ExecuteQuery(query).Where(p => p.Categories.Contains(q.Category));
            if(results.Count() <= 0)
            {
                return null;
            }
            return results.ElementAt((new Random()).Next(0, results.Count()));
        }

        private Question ProcessStackOverflowEntry(SyndicationItem item, string category)
        {
            return new Question("StackOverflow", item.Links[0].Uri.ToString())
            {
                Content = item.Summary.Text.ToString(),
                Category = category,
                Title = item.Title.Text.ToString(),
                CreatedOn = item.PublishDate.ToUniversalTime().DateTime,
                UpdatedOn = item.LastUpdatedTime.ToUniversalTime().DateTime,
                Answered = false,
                AssignedTo = "unassigned"
            };
        }
        
    }
}
