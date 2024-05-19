function st = settling_time_num(sys, x0, tf, thresh, yi, yf)
    [y, tout] = initial(sys, x0, tf);
    err = abs(y-yf);
    tol = (1-thresh)*abs(yf - yi);
    seti = find(err > tol, 1, 'last');
    ns = length(tout);
    if isempty(seti)
      % Pure gain
      st = 0;
    elseif seti==ns
      % Has not settled
      st = NaN;
    else
      st = tout(seti);
    end
end