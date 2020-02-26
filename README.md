# TransferPublisher

A simple extension for URLSession to create a Combine Publisher for a URLDownloadTask, the same as you can already do with a data task.

The publisher will continously publish Output as an enum either of: 
* `downloading` (with tuple bytes received and bytes expected); or 
* `completed` (with the data as an associated value)

The publisher Failure is an `Error`.

Here it is as just a gist: https://gist.github.com/cenkbilgen/d28a1ab12aca6bdf89c3e3c878052ea8

