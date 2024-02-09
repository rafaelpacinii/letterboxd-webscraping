# First part: getting the path to the movie page ----------------------
url_movies_list <- "https://letterboxd.com/films/ajax/popular/page/"
user_agent <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.3"
num_pages <- 100

req_base <- httr2::request(url_movies_list) |>
  httr2::req_user_agent(user_agent) |>
  httr2::req_url_query(`esiAllowFilters` = "true")

reqs <- purrr::map(1:num_pages, ~ {
  req_base |>
    httr2::req_url_path_append(`page_number` = glue::glue("{.x}/"))
})

resps <- httr2::req_perform_parallel(reqs, progress = TRUE, on_error = "continue")

movies <- purrr::map_dfr(resps, ~ {
  httr2::resp_body_html(.x) |>
    rvest::html_elements(".film-poster") |>
    rvest::html_attr("data-target-link") |>
    data.frame()
})