/* custom file for eades microservices api first lab */
package swagger

import (
	"fmt"
	"log"
	"net/http"
	"io/ioutil"
	"html/template"
	"strconv"
	// NEW IN LAB DEPLOYMENT ON KUBERNETES PART2: Import a redis API
	"github.com/mediocregopher/radix/v3"
)

var urls map[string]string = make(map[string]string)

func Configure(args []string) {
	for i := 0; i < len(args)/2; i++ {
		urls[args[2*i]] = args[2*i + 1]
	}
}

func GetAllNews(w http.ResponseWriter, r *http.Request) {
	
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	
	// PROCESSING STAGE 1
	// Get information from news and weather services
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
			
	// NEW IN LAB DEPLOYMENT ON KUBERNETES PART2: Use redis to store the number of page visits
	// PROCESSING STAGE 1A
	// Retreive the current number of visits from redis and increment it before setting the
	// new value in redis and displaying it on the webpage.
	// --> connect to redis
	conn, errR := radix.Dial("tcp", "localhost:6379")
	if errR != nil {
		fmt.Fprintln(w, "allthenews[ERROR]: Can't connect to redis. " + errR.Error() + "<br>")
	}
	defer conn.Close()
	
	// --> declare the count variable (this is initialised to 0 by default and will be used with that
        //     value if the variable does not exist in redis yet)
	var theCount int = 0
	// --> check if the count value exists in redis
	var exists int
	errR2 := conn.Do(radix.Cmd(&exists, "EXISTS", "count"))
	if errR2 != nil {
		fmt.Fprintln(w, "allthenews[ERROR]: EXISTS in redis failed. " + errR2.Error() + "<br>")
	} else if exists != 0 {
		// --> as the count value exists, get the count value
		errR3 := conn.Do(radix.Cmd(&theCount, "GET", "count"))
		if errR3 != nil {
			fmt.Fprintln(w, "allthenews[ERROR]: GET in redis failed. " + errR3.Error() + "<br>")
		} else {
			// --> increment the count value
			theCount++
		}
	}
	// --> set the new count value in redis
	respR := conn.Do(radix.Cmd(nil, "SET", "count", strconv.Itoa(theCount)))
	if (respR != nil) {
		fmt.Fprintln(w, "allthenews[ERROR]: SET in redis failed. " + respR.Error() + "<br>")
	}

	// NEW IN LAB DEPLOYMENT ON KUBERNETES PART2: Include an insert for the visit count retrieved from redis.
	// Create the inserts for the HTML file, which is only a skeleton with no information.
	inserts := struct {
    		News string
		Weather string
		Count int
	}{
		fetchedStrings["news"],
		fetchedStrings["weather"],
		theCount,
	}
	
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

