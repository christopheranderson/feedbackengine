using Microsoft.WindowsAzure.Storage.Table;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FeedbackEngine_WebJobs.Models
{
    class People : TableEntity
    {
        public People()
        {
            this.PartitionKey = "People";
        }
        public new string RowKey { get { return this.Email; } set { Email = value; } }
        public string Name { get; set; }
        public string Email { get; set; }
        public string Slack { get; set; }
        [IgnoreProperty]
        private bool _slackNotify { get; set; }
        public bool SlackNotify { get { return this._slackNotify && this.Slack != null; } set { this._slackNotify = value; } }
        [IgnoreProperty]
        private bool _emailNotify { get; set; }
        public bool EmailNotify { get { return this._emailNotify && this.Email != null; } set { this._emailNotify = value; } }
        public string Categories { get; set; }

        public List<string> GetCategoriesToList()
        {
            return new List<string>(Categories.Split(','));
        }

        public void SetCategoriesFromList(List<string> l)
        {
            this.Categories = String.Join(",", l.ToArray<string>());
        }

    }
}
