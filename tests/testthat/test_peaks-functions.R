test_that(".peaks_replace_intensity works", {
    int <- c(0, 1, 2, 3, 1, 0, 0, 0, 0, 1, 3, 10, 6, 2, 1, 0, 1, 2, 0,
             0, 1, 5, 10, 5, 1)
    x <- cbind(mz = 1:length(int), intensity = int)
    res <- .peaks_replace_intensity(x, 1L, centroided = FALSE)
    expect_equal(res, x)
    res <- .peaks_replace_intensity(x, 1L, centroided = FALSE, threshold = 3)
    int_exp <- c(0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 10, 6, 2, 1, 0, 0, 0, 0, 0,
                 1, 5, 10, 5, 1)
    expect_equal(res[, "intensity"], int_exp)
    expect_warning(res <- .peaks_replace_intensity(x, 1L, threshold = max, value = 3))
    expect_equal(res, x)
    res <- .peaks_replace_intensity(x, 1L, threshold = max,
                                    value = 3, centroided = TRUE)
    expect_true(all(res[, "intensity"] == 3))

    res <- .peaks_replace_intensity(x, 1L, function(z, ...) min(z[z > 0]),
                                    centroided = TRUE)
    int_exp <- c(0, 0, 2, 3, 0, 0, 0, 0, 0, 0, 3, 10, 6, 2, 0, 0, 0, 2, 0, 0,
                 0, 5, 10, 5, 0)
    expect_equal(res[, "intensity"], int_exp)

    res <- .peaks_replace_intensity(x, 1L, centroided = TRUE, msLevel = 2L)
    expect_equal(res[, "intensity"], int)

    ## Working with NAs.
    x[4, 2] <- NA
    res <- .peaks_replace_intensity(x, 1L, centroided = TRUE, threshold = 4)
    expect_equal(res[, 2], c(0, 0, 0, NA, 0, 0, 0, 0, 0, 0, 0, 10, 6,
                             0, 0, 0, 0, 0, 0, 0, 0, 5, 10, 5, 0))
})

test_that(".peaks_filter_intensity works", {
    ints <- c(5, 3, 12, 14.4, 13.3, 9, 3, 0, NA, 21, 89, 55, 33, 5, 2)
    x <- cbind(mz = seq_along(ints), intensity = ints)
    res <- .peaks_filter_intensity(x, spectrumMsLevel = 1L)
    expect_equal(res[, 1], c(1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15))

    res <- .peaks_filter_intensity(x, spectrumMsLevel = 1L, msLevel = 2L)
    expect_equal(res, x)

    res <- .peaks_filter_intensity(x, spectrumMsLevel = 1L, intensity = c(5, 15))
    expect_equal(res[, 1], c(1, 3, 4, 5, 6, 14))
})

test_that(".peaks_filter_intensity_function works", {
    ints <- c(5, 3, 12, 14.4, 13.3, 9, 3, 0, NA, 21, 89, 55, 33, 5, 2)
    x <- cbind(mz = seq_along(ints), intensity = ints)
    res <- .peaks_filter_intensity_function(
        x, spectrumMsLevel = 1L, intfun = function(x) x > 0)
    expect_equal(res[, 1], c(1, 2, 3, 4, 5, 6, 7, 10, 11, 12, 13, 14, 15))

    res <- .peaks_filter_intensity_function(
        x, spectrumMsLevel = 1L,
        intfun = function(z) z > max(z, na.rm = TRUE) / 2)
    expect_true(all(res[, "intensity"] > 89/2))

    res <- .peaks_filter_intensity_function(x, spectrumMsLevel = 1L,
                                            msLevel = 2L)
    expect_equal(res, x)

    expect_error(.peaks_filter_intensity_function(
        x, spectrumMsLevel = 1L, function(x) FALSE),
        "does not return a")
    expect_error(.peaks_filter_intensity_function(
        x, spectrumMsLevel = 1L, function(x) which(is.na(x))),
        "does not return a")
})

test_that(".peaks_bin works", {
    int <- c(0, 1, 2, 3, 1, 0, 0, 0, 0, 1, 3, 10, 6, 2, 1, 0, 1, 2, 0,
             0, 1, 5, 10, 5, 1)
    x <- cbind(mz = 1:length(int), intensity = int)

    res <- .peaks_bin(x, spectrumMsLevel = 1L)
    expect_identical(res[, 2], x[, 2])
    expect_identical(res[, 1], x[, 1] + 0.5)

    res <- .peaks_bin(x, spectrumMsLevel = 1L, binSize = 2L)
    expect_equal(res[, 2], c(1, 5, 1, 0, 1, 13, 8, 1, 3, 0, 6, 15, 1))
    res <- .peaks_bin(x, spectrumMsLevel = 1L, binSize = 2L, FUN = max)
    expect_equal(res[, 2], c(1, 3, 1, 0, 1, 10, 6, 1, 2, 0, 5, 10, 1))
    res <- .peaks_bin(x, spectrumMsLevel = 1L, msLevel = 2L, binSize = 2L)
    expect_identical(res, x)
})

test_that("joinPeaks works", {
    x <- cbind(c(31.34, 50.14, 60.3, 120.9, 230, 514.13, 874.1),
               1:7)
    y <- cbind(c(12, 31.35, 70.3, 120.9 + ppm(120.9, 5),
                 230 + ppm(230, 10), 315, 514.14, 901, 1202),
               1:9)

    res <- joinPeaks(x, y, ppm = 0)
    expect_true(nrow(res$x) == nrow(res$y))
    expect_true(nrow(res$x) == nrow(x) + nrow(y))
    res <- joinPeaks(x, y, ppm = 0, type = "inner")
    expect_true(nrow(res$x) == nrow(res$y))
    expect_true(nrow(res$x) == 0)

    ## ppm 5
    res <- joinPeaks(x, y, ppm = 5)
    expect_true(nrow(res$x) == nrow(res$y))
    expect_true(nrow(res$x) == nrow(x) + nrow(y) - 1)
    expect_true(!is.na(res$x[7, 1]))
    expect_true(!is.na(res$y[7, 1]))
    res <- joinPeaks(x, y, ppm = 5, type = "inner")
    expect_true(nrow(res$x) == nrow(res$y))

    ## ppm 10
    res <- joinPeaks(x, y, ppm = 10)
    expect_true(nrow(res$x) == nrow(res$y))
    expect_true(nrow(res$x) == nrow(x) + nrow(y) - 2)
    res <- joinPeaks(x, y, ppm = 10, type = "inner")
    expect_true(nrow(res$x) == nrow(res$y))
    expect_true(nrow(res$x) == 2)

    ## tolerance 0.01
    res <- joinPeaks(x, y, tolerance = 0.01)
    expect_true(nrow(res$x) == nrow(res$y))
    expect_true(nrow(res$x) == nrow(x) + nrow(y) - 4)
    res <- joinPeaks(x, y, tolerance = 0.01, type = "left")
    expect_true(nrow(res$x) == nrow(res$y))
    expect_equal(res$x, x)
    res <- joinPeaks(x, y, tolerance = 0.01, type = "right")
    expect_true(nrow(res$x) == nrow(res$y))
    expect_equal(res$y, y)
})

test_that(".peaks_pick works", {
    e <- matrix(NA_real_, nrow = 0, ncol = 2,
                dimnames = list(c(), c("mz", "intensity")))
    expect_warning(.peaks_pick(e, spectrumMsLevel = 1), "empty")
    expect_equal(suppressWarnings(.peaks_pick(e, spectrumMsLevel = 1)), e)

    int <- c(0, 1, 2, 3, 1, 0, 0, 0, 0, 1, 3, 10, 6, 2, 1, 0, 1, 2, 0,
             0, 1, 5, 10, 5, 1)
    x <- cbind(mz = seq_along(int), intensity = int)
    expect_equal(.peaks_pick(x, spectrumMsLevel = 2, msLevel = 1), x)
    expect_equal(.peaks_pick(x, spectrumMsLevel = 1, halfWindowSize = 2,
                             snr = 1),
                 cbind(mz = c(4, 12, 18, 23), intensity = c(3, 10, 2, 10)))
    expect_equal(.peaks_pick(x, spectrumMsLevel = 1, halfWindowSize = 2,
                             snr = 5),
                 cbind(mz = c(12, 23), intensity = c(10, 10)))
    expect_equal(.peaks_pick(x, spectrumMsLevel = 1, halfWindowSize = 2,
                             snr = 10), e)
    expect_equal(.peaks_pick(x, spectrumMsLevel = 1, halfWindowSize = 10,
                             snr = 1),
                 cbind(mz = c(12, 23), intensity = c(10, 10)))
    expect_equal(.peaks_pick(x, spectrumMsLevel = 1, halfWindowSize = 2,
                             method = "SuperSmoother", snr = 2),
                 cbind(mz = c(4, 12, 23), intensity = c(3, 10, 10)))

    ## use refineCentroids
    expect_equal(.peaks_pick(x, spectrumMsLevel = 1, halfWindowSize = 2,
                             method = "MAD", snr = 2, k = 1L, ),
                 cbind(mz = mapply(weighted.mean,
                                   x = list(3:5, 11:13, 22:24),
                                   w = list(int[3:5], int[11:13], int[22:24])),
                       intensity = c(3, 10, 10)))
})

test_that(".peaks_smooth works", {
    e <- matrix(NA_real_, nrow = 0, ncol = 2,
                dimnames = list(c(), c("mz", "intensity")))
    expect_warning(.peaks_smooth(e, spectrumMsLevel = 1), "empty")
    expect_equal(suppressWarnings(.peaks_smooth(e, spectrumMsLevel = 1)), e)

    cf <- matrix(0.2, nrow = 5, ncol = 5)
    int <- 1:10
    x <- cbind(mz = seq_along(int), intensity = int)
    expect_equal(.peaks_smooth(x, spectrumMsLevel = 1, coef = cf),
                 cbind(mz = x[, 1L], intensity = rep(3:8, c(3, 1, 1, 1, 1, 3))))
})

test_that(".peaks_filter_mz_range works", {
    p <- cbind(mz = c(2, 5.6, 123.2, 422.8, 599.3, 599.4, 599.5, 743.1),
               intensity = 1:8)
    expect_warning(res <- .peaks_filter_mz_range(
                       p, 1L, mz = range(numeric())), "Inf")
    expect_equal(res, p)

    res <- .peaks_filter_mz_range(p, 1L, msLevel = 2)
    expect_equal(res, p)

    res <- .peaks_filter_mz_range(p, 1L, mz = c(200, 600))
    expect_equal(res[, "intensity"], c(4, 5, 6, 7))
})

test_that(".peaks_match_mz_value works", {
    p <- cbind(mz = c(2, 5.6, 123.2, 422.8, 599.3, 599.4, 599.5, 743.1),
               intensity = 1:8)
    res <- .peaks_filter_mz_value(p, 1L, mz = numeric())
    expect_true(is.matrix(res))
    expect_true(nrow(res) == 0)
    expect_equal(colnames(res), c("mz", "intensity"))
    res <- .peaks_filter_mz_value(p, 1L, mz = NA)
    expect_true(is.matrix(res))
    expect_equal(colnames(res), c("mz", "intensity"))
    expect_true(nrow(res) == 0)

    res <- .peaks_filter_mz_value(p, 1L, mz = 5, tolerance = 1)
    expect_equal(unname(res[, "intensity"]), 2)
    res <- .peaks_filter_mz_value(p, 1L, mz = c(5.5, 599.41), tolerance = 0.1)
    expect_equal(unname(res[, "intensity"]), c(2, 6))

    res <- .peaks_filter_mz_value(p, 1L, mz = c(123, 742.2),
                                  tolerance = c(0.2, 1))
    expect_equal(unname(res[, "intensity"]), c(3, 8))
})

test_that("joinPeaksGnps works", {
    a <- cbind(mz = c(10, 36, 63, 91, 93),
               intensity = c(14, 15, 999, 650, 1))
    a_pmz <- 91

    b <- cbind(mz = c(10, 12, 50, 63, 105),
               intensity = c(35, 5, 16, 999, 450))
    b_pmz <- 105

    expect_equal(joinPeaksGnps(a, b), joinPeaks(a, b))
    expect_equal(joinPeaksGnps(a, b, xPrecursorMz = 91),
                 joinPeaks(a, b))
    expect_equal(joinPeaksGnps(a, b, xPrecursorMz = 3, yPrecursorMz = 3),
                 joinPeaks(a, b))

    res <- joinPeaksGnps(a, b, xPrecursorMz = a_pmz, yPrecursorMz = b_pmz,
                         type = "left")
    expect_true(nrow(res$x) > nrow(a))  # peaks can match multiple
    ## peak 36 matches no peak in b directly, but matches peak 50 in b
    ## considering the precursor difference
    expect_true(sum(res$x[, 1] == 36) == 2)

    res_2 <- joinPeaksGnps(b, a, xPrecursorMz = b_pmz, yPrecursorMz = a_pmz,
                           type = "left")
    expect_equal(res_2$x[, 1], c(10, 12, 50, 50, 63, 105, 105))

    ## example with multi matches.
    a <- cbind(mz = c(10, 26, 36, 63, 91, 93),
               intensity = c(14, 10, 15, 999, 650, 1))
    a_pmz <- 91

    b <- cbind(mz = c(10, 12, 24, 50, 63, 105),
               intensity = c(35, 10, 5, 16, 999, 450))
    b_pmz <- 105

    res <- joinPeaksGnps(a, b, xPrecursorMz = a_pmz, yPrecursorMz = b_pmz,
                         type = "left")
    expect_equal(res$x[, 1], c(10, 10, 26, 36, 36, 63, 91, 91, 93))
    expect_equal(res$y[, 1], c(10, 24, NA, NA, 50, 63, NA, 105, NA))

    ## Example with peaks from a matching multiple peaks in b and vice versa
    a <- cbind(mz = c(10, 12, 14, 16, 19),
               intensity = 1:5)
    a_pmz <- 4
    b <- cbind(mz = c(10, 14, 16, 17, 19, 22),
               intensity = 1:6)
    b_pmz <- 8

    exp_a <- c(10, 10, 12, 12, 14, 16, 19, NA, NA)
    exp_b <- c(10, 14, NA, 16, 14, 16, 19, 17, 22)

    res <- joinPeaksGnps(a, b, a_pmz, b_pmz, type = "outer")
    expect_equal(res$x[, 1], exp_a)
    expect_equal(res$y[, 1], exp_b)
})
