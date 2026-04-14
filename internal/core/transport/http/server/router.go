package core_http_server

import (
	"net/http"
)

type ApiVersion string

var (
	ApiVersion1 = ApiVersion("v1")
	ApiVersion2 = ApiVersion("v2")
	ApiVersion3 = ApiVersion("v3")
)

type APIVersionRouter struct {
	*http.ServeMux
	apiVersion ApiVersion
}

func NewAPIVersionRouter(
	apiVersion ApiVersion,
) *APIVersionRouter {
	return &APIVersionRouter{
		ServeMux:   http.NewServeMux(),
		apiVersion: apiVersion,
	}
}

func (r *APIVersionRouter) RegisterRoutes(routes ...Route) {
	// Group routes by pattern
	routesByPattern := make(map[string][]Route)
	for _, route := range routes {
		pattern := "/" + string(r.apiVersion) + route.Path
		routesByPattern[pattern] = append(routesByPattern[pattern], route)
	}

	// Register each pattern once with a handler that checks the method
	for pattern, patternRoutes := range routesByPattern {
		r.HandleFunc(pattern, func(w http.ResponseWriter, req *http.Request) {
			for _, route := range patternRoutes {
				if req.Method == route.Method {
					route.Handler(w, req)
					return
				}
			}
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		})
	}
}
