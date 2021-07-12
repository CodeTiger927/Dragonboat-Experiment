// Copyright 2017,2018 Lei Ni (nilei81@gmail.com).
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"context"
	"encoding/json"
	// "fmt"
	"net/http"
	// "strconv"
	"time"

	"github.com/lni/dragonboat/v3"
)

type handler struct {
	nh *dragonboat.NodeHost
}

func (h *handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	defer w.Write([]byte("\n"))
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	if r.Method == "GET" {
		res, err := h.nh.SyncRead(ctx, clusterID,[]byte(r.URL.Path))
		if err != nil {
			w.WriteHeader(500)
			w.Write([]byte(err.Error()))
			return
		}
		b, _ := json.Marshal(res)
		w.WriteHeader(200)
		w.Write(b)
	}else if r.Method == "PUT" {
		kv := &KVData{
			Key: r.URL.Path,
			Val: r.FormValue("val"),
		}
		b, err := json.Marshal(kv)
		if err != nil {
			w.WriteHeader(400)
			w.Write([]byte(err.Error()))
			return
		}
		_, err = h.nh.SyncPropose(ctx, h.nh.GetNoOPSession(clusterID), b)
		if err != nil {
			w.WriteHeader(500)
			w.Write([]byte(err.Error()))
			return
		}
		w.WriteHeader(200)
		w.Write([]byte("Successful"));
	} else {
		w.WriteHeader(405)
		w.Write([]byte("Method not supported"))
	}
	cancel();
}