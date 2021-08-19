{{ $repourl := .Info.RepositoryURL -}}

{{ range .Versions }}
<a name="{{ .Tag.Name }}"></a>

## {{ if .Tag.Previous }}[{{ .Tag.Name }}]({{ $repourl }}/compare/{{ .Tag.Previous.Name }}...{{ .Tag.Name }}){{ else }}{{ .Tag.Name }}{{ end }}

> {{ datetime "2006-01-02" .Tag.Date }}

{{ range .CommitGroups -}}
### {{ .Title }}
{{ range .Commits -}}

{{ $title := cat "<a class=\"commit-link\"" "data-hovercard-type=\"commit\"" (list "data-hovercard-url=\"" (list "tami5" "sql.nvim" "commit" .Hash.Long "hovercard" | join "/") "\"" | join "") (list "href=\"" (list $.Info.RepositoryURL "commit" .Hash.Long | join "/") "\"" | join "") ">" (list "<tt>" .Hash.Short "</tt>" | join "") "</a>" (regexReplaceAll `URL` (regexReplaceAll `\[(.*)(\d\d)\]\(.*?\)` .Subject "<a href=\"URL/pull/${2}\">${1}${2}</a>") $repourl) -}}
{{ if .TrimmedBody }}<dl><dd><details><summary> {{ else }}- {{ end }}{{ $title }}{{- range $idx, $ref := .Refs }}{{if not (regexMatch $ref.Ref $title)}} {{- if $idx }}, {{ end }}<a class="issue-link js-issue-link" data-error-text="Failed to load title" data-permission-text="Title is private" data-url="{{ $repourl }}/issues/{{ $ref.Ref }}" data-hovercard-type="issue" data-hovercard-url="/tami5/sql.nvim/issues/{{ $ref.Ref }}/hovercard" href="{{ $repourl }}/issues/{{ $ref.Ref}}"> #{{ $ref.Ref}}</a>{{ end -}}{{end}} {{- if .TrimmedBody }}</summary>

{{ .TrimmedBody }}
</details></dd></dl>{{- end }}
{{ end }}
{{ end -}}

{{- if .RevertCommits -}}
### Reverts

{{ range .RevertCommits -}}
* {{ .Revert.Header }}
{{ end }}
{{ end -}}

{{- if .NoteGroups -}}
{{ range .NoteGroups -}}
### {{ .Title }}

{{ range .Notes }}
{{ .Body }}
{{ end }}
{{ end -}}
{{ end -}}
{{ end -}}
