using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using System.IO;

namespace QuestionProcessor
{
    class QuestionProcessorConfig
    {
    }
    public class listConfigs
    {
        public IList<ConfigProfile> Configs { get; set;}
    }
    public class ConfigList
    {
        public listConfigs Configs { get; set; }
        public ConfigProfile Config { get; set; }
        public string ConfigFilePath { get; set; }

        private void loadCFG()
        {
            //load config
            Console.Out.WriteLine("Loading congif: private void loadCFG()");
            if (ConfigFilePath.Length == 0)
                return;
            try
            {
                string fJson = File.OpenText(ConfigFilePath).ReadToEnd();
                Configs = (JsonConvert.DeserializeObject<listConfigs>(fJson));
                Config = Configs.Configs[0];
            }
            catch (Exception ex)
            {
                Console.Out.WriteLine("Error loading config: " + ex.Message);
            }
            return;
        }
    }
    public class ActionItem
    {
        public string Name { get; set; }
        public string Type { get; set; }
        public string ActionText { get; set; }
    }
    public class ConfigProfile
    {
        public string ProfileName { get; set; }
        public string LogDB { get; set; }
        public string DestinationDB { get; set; }
        public IList<ActionItem> Sources { get; set; }
        public IList<ActionItem> Commands { get; set; }
    }
}
