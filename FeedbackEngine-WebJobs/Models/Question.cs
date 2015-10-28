using Microsoft.WindowsAzure.Storage.Table;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Security.Cryptography;

namespace FeedbackEngine_WebJobs.Models
{
    public class Question : TableEntity
    {
        public Question(){
            // do nothing
        }
        public Question(string source, string url)
        {
            this.PartitionKey = source;
            this.RowKey = url.GetHashCode().ToString() ;
            this.Url = url;
            this.Source = source;
        }

        public string ShortId { 
            get {
                // return null or {{category}}-{{last 6 characters of rowkey}} (i.e. Web-123456)
                return (this.RowKey != null && this.Category != null) ? this.Category + "-" + this.RowKey.ToString().Substring(this.RowKey.ToString().Length < 6 ? 0 : this.RowKey.ToString().Length - 6) : null;
            }
            set {}
        }
        public string Url { get; set; }
        public string Category { get; set; }
        public string Content { get; set; }
        public string Title { get; set; }
        public DateTime CreatedOn { get; set; }
        public DateTime UpdatedOn { get; set; }
        public string Source { get; set; }
        public string AssignedTo { get; set; }
        public bool Answered { get; set; }

        
    }
}
