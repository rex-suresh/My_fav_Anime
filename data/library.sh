#! /bin/bash

#---- Helper functions ---

function get_field() {
  local field=$1
  local data="$2"
  
  local info=$( cut -d"|" -f${field} <<< "${data}" )
  echo "${info}"
}

function get_id() {
  local data="$1"
  get_field 1 "${data}"
}

function get_name(){
  local data="$1"
  get_field 2 "${data}"
}

function get_full_name(){
  local data="$1"
  get_field 3 "${data}"
}

function get_series(){
  local data="$1"
  get_field 4 "${data}"
}

function get_information(){
  local data="$1"
  get_field 5 "${data}"
}

#---- Generating functions ----

function generate_tag() {
  local tag=$1
  local id=$2
  local class=$3
  local content="$4"

  local html="<${tag} id=\"${id}\" class=\"${class}\">${content}</${tag}>"
  
  if [[ -z ${class} ]]
  then
    html="<${tag} id=\"${id}\">${content}</${tag}>"
  
  fi

  if [[ -z ${id} ]]
  then
    html="<${tag} class=\"${class}\">${content}</${tag}>"
  fi


  if [[ -z ${id} ]] && [[ -z ${class} ]]
  then
    html="<${tag}>${content}</${tag}>"
  fi
  
  echo "${html}"
}

function highlight_series() {
  local series="$1"
  local information="$2"

  sed "s:${series}:<strong>${series}</strong>:" <<< "${information}"
}

function generate_profile_view() {
  local name="$1"
  local full_name="$2"
  local IMAGES_DIR=$3

  local view_block="<img src=\"${IMAGES_DIR}/${name}.png\" alt=\"${full_name}\" title=\"${full_name}\" />"
  local profile_name="$( generate_tag "p" "" "profile-name" "${name}")"

  local view_block="$( generate_tag "div" "" "profile-image" "${view_block}" )"
  local view_block="$( generate_tag "div" "" "profile-view" "${view_block}${profile_name}" )"

  echo "${view_block}"
}

function generate_profile_details() {
  local full_name="$1"
  local series="$2"
  local information="$3"

  local heading="$( generate_tag "h2" "" "" "${full_name}" )"
  local information="$( highlight_series "${series}" "${information}" )"

  local information="$( generate_tag "p" "" "" "${information}" )"
  local details_block="$( generate_tag "div" "" "profile-details" "${heading}${information}" )"

  echo "${details_block}"
}

function generate_card() {
  local data="$1"
  local IMAGES_DIR=$2

  local id=$( get_id "${data}" )
  local name=$( get_name "${data}" )
  local full_name=$( get_full_name "${data}" )
  local series=$( get_series "${data}" )
  local information=$( get_information "${data}" )

  local PROFILE_VIEW_BLOCK="$( generate_profile_view "${name}" "${full_name}" "${IMAGES_DIR}" )"
  local PROFILE_DETAILS_BLOCK="$( generate_profile_details "${full_name}" "${series}" "${information}")"
  
  local PROFILE_BLOCK="$( generate_tag "article" "${id}" "profile" "${PROFILE_VIEW_BLOCK}${PROFILE_DETAILS_BLOCK}" )"

  echo "${PROFILE_BLOCK}"
}

function generate_page_content() {
  local IMAGES_DIR=$1
  local data CARD
  local page_content=""

  local OLDIFS=${IFS}
  local IFS=$'\n'
  for data in ${records[@]}
  do
    CARD="$( generate_card "${data}" "${IMAGES_DIR}" )"
    page_content+="${CARD}"
  done
  local IFS=${OLDIFS}

  echo "${page_content}"
}

function create_page() {
  local RECORDS_FILE="$1"
  local IMAGES_DIR="$2"
  local TEMPLATE="$3"
  # local count

  local OLDIFS=${IFS}
  local IFS=$'\n'
  records=($( tail -n+2 ${RECORDS_FILE} ))
  local IFS=${OLDIFS}

  # [[ -n ${count} ]] && records=($( head -n${count} <<< ${records[@]} ))
  local page_content=$( generate_page_content "${IMAGES_DIR}" )

  sed "s:__PAGE_CONTENT__:${page_content}:" ${TEMPLATE} > ../my_fav_anime_generated.html
  open ../my_fav_anime_generated.html
}

create_page "anime_data.csv" "images" "document_template.html"
