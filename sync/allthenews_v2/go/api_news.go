/* custom file for eades microservices api first lab */
package swagger

import (
	"fmt"
	"log"
	"net/http"
	"io/ioutil"
	"html/template"
)

// NEW IN LAB DEPLOYMENT ON KUBERNETES PART1: Map to store the urls (e.g. http://nf service:8888) as values
//                                                             against
//                                                             source types (e.g. 'news') as keys 
var urls map[string]string = make(map[string]string)

// NEW IN LAB DEPLOYMENT ON KUBERNETES PART1: Function that populates storage from command line arguments
//                                            The arguments passed in on the command line will be
//                                            alternating source type and url, for example:
//                                            "allthenews news http://nf:8888 weather http://wf:8888" 
func Configure(args []string) {
	for i := 0; i < len(args)/2; i++ {
		urls[args[2*i]] = args[2*i + 1]
	}
}

func GetAllNews(w http.ResponseWriter, r *http.Request) {
	
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	
	// PROCESSING STAGE 1
	// Get information from news and weather services
	// NEW IN LAB DEPLOYMENT ON KUBERNETES PART1: Generic loop through the map to handle all sources specified on the command line
	var fetchedStrings map[string]string = make(map[string]string)
	for k, v := range urls {
		resp, err := http.Get(v)
		if (err != nil) {
			fmt.Fprintln(w, "allthenews[ERROR]: Couldn't get " + k + " from site. " + err.Error() + "<br/>")
			log.Printf("allthenews[ERROR]: Couldn't get " + k + " from site. " + err.Error())
		} else {
			if resp.StatusCode == http.StatusOK {
				bodyBytes, err2 := ioutil.ReadAll(resp.Body)
				if (err2 != nil) {
					fmt.Fprintln(w, "allthenews[ERROR]: Couldn't get " + k + " from response." + err2.Error() + "<br/>")
					log.Printf("allthenews[ERROR]: Couldn't get " + k + " from response." + err2.Error())
				} else {
					fetchedStrings[k] = string(bodyBytes)
				}
			} else {
				fmt.Fprintln(w, "allthenews[ERROR]: HTTP returned status " + string(resp.StatusCode) + "<br/>")
				log.Printf("allthenews[ERROR]: HTTP returned status " + string(resp.StatusCode))
			}
		}
	}
		
	// Create the inserts for the HTML file, which is only a skeleton with no information.

	// NEW IN LAB DEPLOYMENT ON KUBERNETES PART1: Create the inserts from the map rather than array
	// (note that we are still using hard-coded sources News and Weather on the template side but
	// this can be made dynamic)
	inserts := struct {
    		News string
		Weather string	
	}{ fetchedStrings["news"], fetchedStrings["weather"] }


	// PROCESSING STAGE 2
	// Read the query parameter "style" and check it against the different allowed values, assigning
	// the appropriate template name to variable templateName.	
	var templateName = ""
	switch r.URL.Query().Get("style") {
	case "plain":
		templateName = "plain.html"
	case "colourful":
		templateName = "colour.html"
	case "blackandwhite":
		templateName = "bandw.html"
	}

	// PROCESSING STAGE 3
	// We are using the template handling library html/template to insert the information fetches from the other
	// services into the page with the requested style (via parameter 'style').
	if (templateName != "") {
		// Now put together an HTML page. The template.ParseFiles() function inserts the values from structure
		// 'inserts' into the chosen template.
		t, _ := template.ParseFiles(templateName)
		t.Execute(w, inserts)
	} else {
		fmt.Fprintln(w, "allthenews[ERROR]: Invalid style parameter.<br>")
		log.Printf("allthenews[ERROR]: Invalid style parameter.")
	}
}
