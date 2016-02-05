using FeedbackEngine_WebJobs.Models;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using System.Diagnostics;
using System.Net.Http;
using System.Net.Http.Headers;

namespace FeedbackEngine_WebJobs
{
    public class Messages
    {
        // WebJob Functions (This are loaded by the SDK, which looks for functions with various attributes defined by the WebJobs SDK

        /// <summary>
        /// Receives a WebHook Message and passes it through to Slack, without modification. This allows us to post messages without hitting the Queue.
        /// </summary>
        /// <param name="context">This contains information about the incoming Webhook</param>
        /// <param name="trace">This is used to log from the application to the Azure WebJobs Dashboard</param>
        /// <returns></returns>
        public async Task PassSlackMessage([WebHookTrigger] WebHookContext context, TraceWriter trace)
        {
            trace.Info("Route: /Slack/NewSuggestion received data");
            JObject dataEvent = JObject.Parse(await context.Request.Content.ReadAsStringAsync());
            trace.Info("Data: \n" + dataEvent.ToString());

            await SendJSONtoURL(dataEvent, ConfigurationManager.AppSettings["SLACK_CustomerNotificationsHook"], trace);
        }

        /// <summary>
        /// Grabs messages from the "SlackMessage" Queue and posts them to the Slack Webhook specified in App Settings under "SLACK_CustomerNotificationsHook"
        /// </summary>
        /// <param name="m">Message from the Queue to be posted to Slack</param>
        /// <param name="trace">This is used to log from the application to the Azure WebJobs Dashboard</param>
        /// <returns></returns>
        public async Task ProcessSlackMessage([QueueTrigger("SlackMessage")] Message m, TraceWriter trace)
        {
            trace.Info(String.Format("Dequeued message for {0}: {1}", m.to, m.contents));
            await SendSlackMessage(m, trace);
        }

        // Private Functions

        private async Task SendSlackMessage(Message m, TraceWriter trace)
        {
            JObject slackMessage = new JObject();
            slackMessage["username"] = "customer-bot";
            slackMessage["text"] = m.contents;
            slackMessage["icon_emoji"] = ":zumo:";

            if (m.to != null) {
                slackMessage["channel"] = m.to;
            }

            trace.Info("Data: \n" + slackMessage.ToString());
            await SendJSONtoURL(slackMessage, ConfigurationManager.AppSettings["SLACK_CustomerNotificationsHook"], trace);
        }

        private async Task<bool> SendJSONtoURL(JObject json, string url, TraceWriter trace)
        {
            var client = new HttpClient();
            var response = await client.PostAsJsonAsync(url, json);

            if (response.StatusCode != HttpStatusCode.OK) {
                trace.Error(String.Format("Status Code: {0} - Content: {1}", response.StatusCode, response.Content));
                return false;
            }

            trace.Info("Finished sending message to Slack");
            return true;
        }
    }
}
