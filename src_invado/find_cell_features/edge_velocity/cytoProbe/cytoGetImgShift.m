function [x_shift, y_shift] = cytoGetImgShift(img1, img2)ccImg = normxcorr2(img1, img2);% get approximate location of maximum cross-correlation[x_shift_init, y_shift_init, max_cc] = find(max(ccImg(:)) == ccImg);% fit 2D Gauss-peak to the maximum peakpeak_region = ccImg(x_shift_init-5:x_shift_init+5, y_shift_init-5:y_shift_init+5);x_shift_init = 0;y_shift_init = 0;estimages = fminsearch(MultiVarGaussFun, [x_shift_init, y_shift_init]);function res = MultiVarGauss_fun(params)        rho = sig1*sig2/sig12;    1 / (2*pi*sig1*sig2*sqrt(1-rho^2)) * exp(-z ./ (2*(1-rho^2)));    A = params(1);    lambda = params(2);    sse = sum(ErrorVector .^ 2);