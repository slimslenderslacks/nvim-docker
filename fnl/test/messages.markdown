### create-notebook

* not streamed
* all cells are ready as soon as we see the complete event
* function_call `arguments` are not json-encoded

```json
{"function_call":
 {"name":"create-notebook",
  "arguments":
  {"notebook":"docker_init",
   "reason":"project is not dockerized",
   "cells":
   {"cells":
    [{"kind":1,
      "languageId":"markdown",
      "value":"## Dockerize Your Project\nGet started with our pre-populated `docker init`"},
     {"kind":2,
      "languageId":"shellscript",
      "value":"docker init"},
     {"kind":1,
      "languageId":"markdown",
      "value":"Run your container initialized from `docker init`"},
     {"kind":2,
      "languageId":"shellscript",
      "value":"# --build forces a fresh build; -d runs in detached mode and is required for Docker AI recommendations\ndocker compose up --build -d"}]}}}}
```

### cell-execution

* function_call `function_call.name` is only sent in the first message
* in first message, `arguments` is probably an empty string
* the `metadata.id` is always sent
* the `function_call.arguments` should be appended to a string, which builds up a json argument
* the final json payload will have `command` and `reason` strings 
* after the `complete` message arrives, the json payload should be ready to parse and then run the cell-execution function

```
```

### update-file

* function_call `function_call.name`  is only sent in the first message
* the `metadata.id` is always sent
* the `function_call.arguments` should be appended to a string, which builds up a json argument
* the final json payload will have `edit` `startLine` `path` and `languageId`
* after the `complete` message arrives, or a new function_call starts, 
  the json payload should be ready to parse and then run the update-file command

### content

* `content` will probably start off empty
* subsequent messages with the same `metadata.id` should be appended
* this one should append to buffers as they stream in, no waiting until the end to call functions
* the content for one cell will be complete when either a new function_call starts -or- the complete true message arrives
