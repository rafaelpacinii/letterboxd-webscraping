# First part: getting the paths to the movies page --------------------
url_base <- "https://letterboxd.com"
user_agent <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.3"
num_pages <- 100

req_base_pl <- httr2::request(url_base) |>
  httr2::req_user_agent(user_agent) |>
  httr2::req_url_path(path = "/films/ajax/popular/page/") |>
  httr2::req_url_query(`esiAllowFilters` = "true")

reqs_pl <- purrr::map(1:num_pages, ~ {
  req_base_pl |>
    httr2::req_url_path_append(page_number = glue::glue("{.x}/"))
})

resps_pl <- httr2::req_perform_parallel(reqs_pl, progress = "FP: responses", on_error = "continue")

movies_path_list <- purrr::map(resps_pl, ~ {
  httr2::resp_body_html(.x) |>
    rvest::html_elements(".film-poster") |>
    rvest::html_attr("data-target-link")
}, .progress = "FP: movies_path_list")

movies_path <- unlist(movies_path_list)

# Second part: getting the data from each movie page ------------------
reqs_ml <- purrr::map(movies_path, ~ {
  httr2::request(url_base) |>
    httr2::req_user_agent(user_agent) |>
    httr2::req_url_path(path = .x)
})

resps_ml <- httr2::req_perform_parallel(reqs_ml, progress = "SP: responses", on_error = "continue")

movies_data <- purrr::map(resps_ml, ~ {
  movie_data <- list(
    nome = httr2::resp_body_html(.x) |>
      rvest::html_elements(".cast-list .text-slug") |>
      rvest::html_text() |>
      paste0(collapse = ", ")
  )
}, .progress = "SP: movies_data")
