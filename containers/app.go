/*
Copyright 2018 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/*
When compiled, this application provides endpoints to make demonstrating
various security best practices easier.
*/

package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/user"
)

// hostnameHandler handles /hostname and returns the result of os.Hostname()
func hostnameHandler(w http.ResponseWriter, r *http.Request) {
	h, err := os.Hostname()
	if err != nil {
		fmt.Fprintf(w, "unable to get hostname: %s", err)
	}
	fmt.Fprintf(w, "You are querying host %s\n", h)
}

// getUserHandler handles /getuser and returns the result of user.Current()
func getUserHandler(w http.ResponseWriter, r *http.Request) {
	user, err := user.Current()
	if err != nil {
		fmt.Fprintf(w, "unable to get user: %s", err)
	}

	fmt.Fprintf(w, "User: %s\nUID: %s\nGID: %s\n", user.Username, user.Uid, user.Gid)
}

// userFileHandler handles /userfile and returns the contents of user.txt
func userFileHandler(w http.ResponseWriter, r *http.Request) {
	file, err := ioutil.ReadFile("user.txt")

	if err != nil {
		fmt.Fprintf(w, "unable to open user.txt: %s", err)
	}

	fmt.Fprintf(w, "%s\n", string(file))
}

// rootFileHandler handles /rootfile and returns the contents of root.txt
// which is owned by root in the container
func rootFileHandler(w http.ResponseWriter, r *http.Request) {
	file, err := ioutil.ReadFile("root.txt")

	if err != nil {
		fmt.Fprintf(w, "unable to open root.txt: %s", err)
	}

	fmt.Fprintf(w, "%s\n", string(file))
}

// procFileHandler handles /procfile and returns the contents of /proc/cpuinfo
// which can be blocked by AppArmor
func procFileHandler(w http.ResponseWriter, r *http.Request) {
	file, err := ioutil.ReadFile("/proc/cpuinfo")

	if err != nil {
		fmt.Fprintf(w, "unable to open root.txt: %s", err)
	}

	fmt.Fprintf(w, "%s\n", string(file))
}

func main() {
	http.HandleFunc("/", hostnameHandler)
	http.HandleFunc("/hostname", hostnameHandler)
	http.HandleFunc("/getuser", getUserHandler)
	http.HandleFunc("/userfile", userFileHandler)
	http.HandleFunc("/rootfile", rootFileHandler)
	http.HandleFunc("/procfile", procFileHandler)
	log.Print("Starting web server on port 8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
