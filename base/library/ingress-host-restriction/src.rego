package ingresshostrestriction

violation[{"msg": msg, "details": {"host": host, "namespace": namespace, "paths": paths}}] {
    name := input.review.object.metadata.name
    namespace := input.review.namespace
    host := input.review.object.spec.rules[i].host
    paths := {x | x = input.review.object.spec.rules[i]["http"]["paths"][_].path}
    whitelist := input.parameters.namespacePathWhitelist

    # resource kind is Ingress
    input.review.kind.kind == "Ingress"

    # always allow deletion of offending ingresses
    input.review.operation != "DELETE"

    # ingress host matches the restricted host
    host == input.parameters.host
    
    # namespace+host+path(s) is not in the list of allowed namespaces+paths
    not allowed(whitelist, namespace, paths)

    msg := sprintf("Ingress '%v' denied; the host and/or path values are not permitted for this namespace host=%v namespace=%v paths=%v", [name, host, namespace, paths])
}

allowed(whitelist, namespace, paths) {
    # check that this namespace has whitelisted paths
    count(whitelist[namespace]) > 0

    # all the paths should be in the list of whitelisted paths for this namespace
    whitelisted_paths := {x | x = whitelist[namespace][_]}
    paths_in_whitelist := paths & whitelisted_paths
    count(paths_in_whitelist) == count(paths)
}
