+ Feature name: `spa_http_api`
+ Start date: 22.01.2020
+ RFC PR: [iotaledger/protocol-rfcs#0002](https://github.com/iotaledger/protocol-rfcs/pull/0002)

# Summary

This RFC lays out a common set of HTTP and WebSocket APIs, which must be implemented by an IOTA node software
implementation, which wants to be compatible with the IOTA Foundation's web [SPA](https://en.wikipedia.org/wiki/Single-page_application) for node software.

# Motivation

Through Dr. Navin Ramachandran's request, a web SPA for all the node implementations
should be realized. In order to enable such SPA to function properly, the teams for the different node implementations
must agree up on a common HTTP/WebSocket API, in order to enable the IOTA Foundation's frontend UX team to create such SPA.

By specifying those API endpoints, the frontend UX team is able to minimize duplicate work and can implement
frontend components which work for multiple node software implementations.

# Detailed design

The API is specified through [OpenAPI Specification 3](https://www.openapis.org/) (OAS) and [AsyncAPI 2](https://www.asyncapi.com/)
specification files. It is suggested that the reader of this RFC looks at the specification files through their
corresponding online editors: [OAS-editor](http://editor.swagger.io/) / [AsyncAPI-editor](https://playground.asyncapi.io/).
The files can be found within this RFC's folder.

* The OAS specification file describes the REST HTTP API.
* The AsyncAPI specification file describes the WebSocket API using [socket.io](https://socket.io/`).
The different channels are meant to be interpreted as socket.io [rooms](https://socket.io/docs/rooms-and-namespaces/).

#### Notes on the routes

The specification files are written in such way, that they cover common needs for [Hornet](https://github.com/gohornet/hornet),
[Bee](https://github.com/iotaledger/bee), [GoShimmer](https://github.com/iotaledger/goshimmer) and [IRI](https://github.com/iotaledger/iri). 

##### Authentication
Since the specified routes expose node level private information (for example neighbors), the routes are protected 
via authentication through a [JWT](https://jwt.io/) (see the corresponding authentication routes for further detail within
the specification files). Please note that the WebSocket route is also authenticated through the JWT but due to a rendering error
on the AsyncAPI-editor's site, the header is not rendered correctly.

The JWT must be carried in the bearer format: `Authorization: bearer <JWT>`.

Since such SPA will only be used by the node operator, the session can simply be invalidated by deleting the JWT on the node
operator's local machine.

##### Neighbors
Using the corresponding fields from `/info`, the application can choose to render certain neighbor specific frontend components or not.
It is important to note that a node software implementation might support autopeering and static neighbors simultaneously.
The API specifies two objects to describe autopeered and static neighbors: `AutopeeredNeighbor` and `StaticNeighbor`.

##### Misc
If the frontend SPA needs to apply slightly different rendering logic dependent on the node software, it can examine
the `/info` route's `app_name` within the response JSON object.

# Drawbacks
* Some data might be important for a node software while not for the other, this means that inherently, there still needs
to be some frontend logic to handle specific node implementation needs.

# Rationale and alternatives

Rationale:
* Having the specification files agreed up on, guarantees that different node implementations are compatible with the
from the frontend UX team produced SPA. 
* OAS and AsyncAPI are common specification files from which directly code can be generated (not for all languages).
* The request/response payloads are specified and therefore ensure a smoother implementation for the frontend UX team.
* Thanks to the specification files, the frontend UX team can start to build the SPA, without actually relying on any backend implementation
being ready.

Alternatives:  
An alternative would be, that every node implementation provides its own set of API. However, this would increase the
complexity for the frontend UX team for no real benefit. Without the specification files it is a free-for-all and
we might end up never creating a SPA in the first place.

# Unresolved questions

- Is the specified API good enough to be able to create a useful web SPA?
- Is there any additional API endpoint needed?
- Do the request/response objects make sense?
