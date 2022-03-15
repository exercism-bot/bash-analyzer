#!/usr/bin/env bash

# Check for boilerplate comments
boilerplate() {
    local comment='# *** PLEASE REMOVE THESE COMMENTS BEFORE SUBMITTING YOUR SOLUTION ***'
    grep -Fxq "$comment" "$filename" \
    && echo '{"comment": "bash.general.boilerplate_comment", "type": "actionable"}'
}

# Other check functions can go here:
# ...


# ------------------------------------------------------------
# Merge results into analysis.json generated by the shellcheck analysis.

comments_array_as_json() {
    jq -n --jsonargs '{comments: $ARGS.positional}' "$@"
}

write_json() {
    local -i shellcheck_comments
    local temp

    # How many shellcheck comments were found?
    shellcheck_comments=$(jq '.comments | length' "$out_dir/analysis.json")

    case "$shellcheck_comments,${#general_comments[@]}" in
        0,0)
            jq -n '{
                summary: "Congrats! No suggestions",
                comments: []
            }' > "$out_dir/analysis.json"
            ;;
        0,*)
            comments_array_as_json "${general_comments[@]}" \
            | jq '.summary = "Some comments"' \
            > "$out_dir"/analysis.json
            ;;
        *,0)
            # no need to alter analysis.json
            : ;;
        *,*)
            temp=$(mktemp)

            # grab the summary from the shellcheck analysis
            summary=$(jq -r .summary "$out_dir/analysis.json")

            # Thanks to https://stackoverflow.com/a/36218044/7552
            jq --arg sum "$summary" --slurp '{
                summary: $sum,
                comments: (reduce .[] as $item ([]; . + $item.comments))
            }' \
                "$out_dir/analysis.json" \
                <(comments_array_as_json "${general_comments[@]}") \
                > "$temp" && mv "$temp" "$out_dir/analysis.json"
            ;;
    esac
}

# ------------------------------------------------------------
analyze() {
    local in_dir=$1 out_dir=$2 snake_slug=$3
    local filename="$in_dir/${snake_slug}.sh"
    local general_comments=()
    local IFS=,

    json=$(boilerplate)
    [[ -n $json ]] && general_comments+=("$json")

    # other checks can go here to add to the "general_comments" array
    # ...

    write_json
}

analyze "$@"
