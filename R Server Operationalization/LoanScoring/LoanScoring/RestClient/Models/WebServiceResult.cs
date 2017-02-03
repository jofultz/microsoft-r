// Code generated by Microsoft (R) AutoRest Code Generator 0.17.0.0
// Changes may cause incorrect behavior and will be lost if the code is
// regenerated.

namespace TechReady.Models
{
    using System.Linq;

    public partial class WebServiceResult
    {
        /// <summary>
        /// Initializes a new instance of the WebServiceResult class.
        /// </summary>
        public WebServiceResult() { }

        /// <summary>
        /// Initializes a new instance of the WebServiceResult class.
        /// </summary>
        /// <param name="success">Boolean flag indicating the success status
        /// of web service execution.</param>
        /// <param name="errorMessage">Error messages if any occurred during
        /// the web service execution.</param>
        /// <param name="consoleOutput">Console output from the web service
        /// execution.</param>
        /// <param name="changedFiles">The filenames of the files modified
        /// during the web service execution.</param>
        public WebServiceResult(bool? success = default(bool?), string errorMessage = default(string), string consoleOutput = default(string), System.Collections.Generic.IList<string> changedFiles = default(System.Collections.Generic.IList<string>), OutputParameters outputParameters = default(OutputParameters))
        {
            Success = success;
            ErrorMessage = errorMessage;
            ConsoleOutput = consoleOutput;
            ChangedFiles = changedFiles;
            OutputParameters = outputParameters;
        }

        /// <summary>
        /// Gets or sets boolean flag indicating the success status of web
        /// service execution.
        /// </summary>
        [Newtonsoft.Json.JsonProperty(PropertyName = "success")]
        public bool? Success { get; set; }

        /// <summary>
        /// Gets or sets error messages if any occurred during the web service
        /// execution.
        /// </summary>
        [Newtonsoft.Json.JsonProperty(PropertyName = "errorMessage")]
        public string ErrorMessage { get; set; }

        /// <summary>
        /// Gets or sets console output from the web service execution.
        /// </summary>
        [Newtonsoft.Json.JsonProperty(PropertyName = "consoleOutput")]
        public string ConsoleOutput { get; set; }

        /// <summary>
        /// Gets or sets the filenames of the files modified during the web
        /// service execution.
        /// </summary>
        [Newtonsoft.Json.JsonProperty(PropertyName = "changedFiles")]
        public System.Collections.Generic.IList<string> ChangedFiles { get; set; }

        /// <summary>
        /// </summary>
        [Newtonsoft.Json.JsonProperty(PropertyName = "outputParameters")]
        public OutputParameters OutputParameters { get; set; }

    }
}