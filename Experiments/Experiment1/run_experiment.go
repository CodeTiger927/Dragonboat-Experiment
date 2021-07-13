package main

import (
	"fmt"
	"bytes"
	"net/http"
	"io/ioutil"
	"io"
	"os"
	"math/rand"
	"flag"
	"time"
)

var (
	readOperations = 1000
	writeOperations = 1000

	keyValueSize = 16
	leaderAddr = ""

	keyNames []string
)

const letterBytes = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

func RandStringBytes(n int) string {
    b := make([]byte, n)
    for i := range b {
        b[i] = letterBytes[rand.Intn(len(letterBytes))]
    }
    return string(b)
}

func makeWriteRequest() {
    client := &http.Client{}

    key := RandStringBytes(keyValueSize);
    val := RandStringBytes(keyValueSize);

    req, err := http.NewRequest(http.MethodPut, "http://" + leaderAddr + "/" + key + "?val=" + val, bytes.NewBuffer(make([]byte,0)))
    if err != nil {
        panic(err)
    }

    resp, err := client.Do(req)
    if err != nil {
        panic(err)
    }

    _, err = ioutil.ReadAll(resp.Body);
    if err != nil {
    	panic(err)
    }
    keyNames = append(keyNames,key)
}

func makeReadRequest() {
    key := keyNames[rand.Int() % len(keyNames)];

    resp, err := http.Get("http://" + leaderAddr + "/" + key)
    if err != nil {
        panic(err)
    }

    _, err = ioutil.ReadAll(resp.Body);
    if err != nil {
    	panic(err)
    }

}

func main() {
	readOperationsPre := flag.Int("read", 1, "Number of read operations")
	writeOperationsPre := flag.Int("write", 1, "Number of write operations")
    leaderAddrPre := flag.String("leaderAddr", "", "Leader node address")
    keyValueSizePre := flag.Int("keyValueSize",16,"number of bytes of the key and values")
	flag.Parse()
    readOperations := *readOperationsPre
    writeOperations := *writeOperationsPre
    leaderAddr = *leaderAddrPre
    keyValueSize = *keyValueSizePre

	makeWriteRequest();
	writeOperations--;
	i := 1;
	veryStart := time.Now()
	for (writeOperations + readOperations) > 0 {
		start := time.Now()
		writeOrRead := ""
		if rand.Int() % (writeOperations + readOperations) < writeOperations {
			writeOperations--;
			makeWriteRequest();
			writeOrRead = "Write"
		}else{
			readOperations--;
			makeReadRequest();
			writeOrRead = "Read "
		}
		elapsed := time.Now().Sub(start)
		io.WriteString(os.Stdout,fmt.Sprintln("Operation ",writeOrRead," #",i,": ",elapsed.Nanoseconds()))
		i++
	}

	io.WriteString(os.Stdout,fmt.Sprintln("Experiment complete successfully, total nanoseconds over all the tests is ",time.Now().Sub(veryStart).Nanoseconds()))
}