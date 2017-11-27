let s:list_of_entries={}
let s:mode_tests=0
fun! javadepsearch#search(...) "{{{
  let params_query=''
  if a:0 == 0
    echohl WARNINGMSG | echo 'NO PARAMETERS SPECIFIED' | echohl NORMAL
  endif
  if a:0 == 1
    let params_query .= 'a:'.a:1
  elseif a:0 >= 2
    let params_query .= 'g:'.a:1.'+a:'.a:2
  endif
  if !s:mode_tests
python3 << EOF
import requests
import vim
import json
str_url = 'https://search.maven.org/solrsearch/select?q=' + vim.eval('params_query')
str_response=requests.get(str_url).text
vim.command("let python_dict = %s" % str_response)
EOF
  else
    let python_dict=javadepsearch#fake_python_dict()
    return
  endif

  let s:list_of_entries = python_dict['response']['docs']
endfunction "}}}

fun! javadepsearch#set_entries(entries) "{{{
  let s:list_of_entries = a:entries
endfunction "}}}

fun! javadepsearch#define_found_artifacts() "{{{
  return map(s:list_of_entries, "get(v:val, 'id')")
endfunction "}}}

fun! javadepsearch#current_dict() "{{{
  return s:list_of_entries
endfunction "}}}

fun! javadepsearch#set_mode_test(mode) "{{{
  let s:mode_tests=a:mode
endfunction "}}}

fun! javadepsearch#extract_versions(str_xml) "{{{
  python3 << EOF
import vim
import re
from lxml import etree

str_xml=vim.eval('a:str_xml')
str_xml=re.sub(r'<\?xml[^?]+\?>', '', str_xml)
doc = etree.fromstring(str_xml)
result = doc.xpath("/metadata/versioning/versions/version/text()")
vim.command("let list_of_versions = []")
for element in result:
  vim.command("call add(list_of_versions, '%s')" % element)
EOF
  return list_of_versions
endfunction "}}}

" This code is used only with testing purposes, it should only be modified
" to add edge cases to test or if search api changes in the future
fun! javadepsearch#fake_python_dict() "{{{
  return {
\  "spellcheck": { "suggestions": [] },
\  "response": {
\  "numFound": 3,
\  "start": 0,
\  "docs": [
\  { "p": "jar", "id": "org.mybatis:mybatis-cdi", "a": "mybatis-cdi", "g": "org.mybatis", "timestamp": 1507946093000, "ec": [ "-sources.jar", "-javadoc.jar", ".jar", ".pom" ], "versionCount": 10, "text": [ "org.mybatis", "mybatis-cdi", "-sources.jar", "-javadoc.jar", ".jar", ".pom" ], "repositoryId": "central", "latestVersion": "1.0.2" },
\  { "p": "jar", "id": "org.mybatis:mybatis-guice", "a": "mybatis-guice", "g": "org.mybatis", "timestamp": 1504972907000, "ec": [ "-sources.jar", "-javadoc.jar", ".jar", ".pom" ], "versionCount": 18, "text": [ "org.mybatis", "mybatis-guice", "-sources.jar", "-javadoc.jar", ".jar", ".pom" ], "repositoryId": "central", "latestVersion": "3.10" },
\  { "p": "jar", "id": "org.mybatis:mybatis", "a": "mybatis", "g": "org.mybatis", "timestamp": 1503219688000, "ec": [ "-javadoc.jar", "-sources.jar", ".jar", ".pom" ], "versionCount": 26, "text": [ "org.mybatis", "mybatis", "-javadoc.jar", "-sources.jar", ".jar", ".pom" ], "repositoryId": "central", "latestVersion": "3.4.5" } ]
\  },
\  "responseHeader": { "status": 0, "params": { "q": "g:org.mybatis", "version": "2.2", "indent": "off", "wt": "json", "spellcheck": "true", "sort": "score desc,timestamp desc,g asc,a asc", "fl": "id,g,a,latestVersion,p,ec,repositoryId,text,timestamp,versionCount", "spellcheck.count": "5" }, "QTime": 0 }
\ }
endfunction "}}}
