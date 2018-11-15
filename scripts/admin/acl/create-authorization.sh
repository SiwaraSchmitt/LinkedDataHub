#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

args=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -b|--base)
    base="$2"
    shift # past argument
    shift # past value
    ;;
    --label)
    label="$2"
    shift # past argument
    shift # past value
    ;;
    --comment)
    comment="$2"
    shift # past argument
    shift # past value
    ;;
    --slug)
    slug="$2"
    shift # past argument
    shift # past value
    ;;
    --uri)
    uri="$2"
    shift # past argument
    shift # past value
    ;;
    --agent)
    agent="$2"
    shift # past argument
    shift # past value
    ;;
    --agent-class)
    agent_class="$2"
    shift # past argument
    shift # past value
    ;;
    --to)
    to="$2"
    shift # past argument
    shift # past value
    ;;
    --to-all-in)
    to_all_in="$2"
    shift # past argument
    shift # past value
    ;;
    --append)
    append=true
    shift # past value
    ;;
    --control)
    control=true
    shift # past value
    ;;
    --read)
    read=true
    shift # past value
    ;;
    --write)
    write=true
    shift # past value
    ;;
    *)    # unknown arguments
    args+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${args[@]}" # restore args

if [ -z "$base" ] ; then
    echo '-b|--base not set'
    exit 1
fi
if [ -z "$label" ] ; then
    echo '--label not set'
    exit 1
fi
if ( [ -z "$agent" ] && [ -z "$agent_class" ] ) ; then
    echo '--agemt or --agent-class not set'
    exit 1
fi
if ( [ -z "$to" ] && [ -z "$to_all_in" ] ) ; then
    echo '--to or --to-all-in not set'
    exit 1
fi
if ( [ -z "$append" ] && [ -z "$control" ] && [ -z "$read" ] && [ -z "$write" ] ) ; then
    echo '--append or --control or --read or --write not set'
    exit 1
fi

args+=("-c")
args+=("${base}ns#Authorization") # class
args+=("-t")
args+=("text/turtle") # content type
args+=("${base}acl/authorizations/") # container

# allow explicit URIs
if [ ! -z "$uri" ] ; then
    auth="<${uri}>" # URI
else
    auth="_:auth" # blank node
fi

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="@prefix acl:	<http://www.w3.org/ns/auth/acl#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="${auth} a ns:Authorization .\n"
turtle+="${auth} rdfs:label \"${label}\" .\n"
turtle+="${auth} foaf:isPrimaryTopicOf _:item .\n"
turtle+="_:item a ns:AuthorizationItem .\n"
turtle+="_:item dct:title \"${label}\" .\n"
turtle+="_:item foaf:primaryTopic ${auth} .\n"

if [ ! -z "$comment" ] ; then
    turtle+="${auth} rdfs:comment \"${comment}\" .\n"
fi
if [ ! -z "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi

if [ ! -z "$agent" ] ; then
    turtle+="${auth} acl:agent <${agent}> .\n"
fi
if [ ! -z "$agent_class" ] ; then
    turtle+="${auth} acl:agentClass <${agent_class}> .\n"
fi
if [ ! -z "$to" ] ; then
    turtle+="${auth} acl:accessTo <${to}> .\n"
fi
if [ ! -z "$to_all_in" ] ; then
    turtle+="${auth} acl:accessToClass <${to_all_in}> .\n"
fi
if [ ! -z "$append" ] ; then
    turtle+="${auth} acl:mode acl:Append .\n"
fi
if [ ! -z "$control" ] ; then
    turtle+="${auth} acl:mode acl:Control .\n"
fi
if [ ! -z "$read" ] ; then
    turtle+="${auth} acl:mode acl:Read .\n"
fi
if [ ! -z "$write" ] ; then
    turtle+="${auth} acl:mode acl:Write .\n"
fi

# set env values in the Turtle doc and sumbit it to the server

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="${base}" | ../../create-document.sh "${args[@]}"