syms z wn t wd

r = taylor(1/2*(exp((-sqrt(1-(wd/wn)^2)*wn+1i*wd)*t)+exp((-sqrt(1-(wd/wn)^2)*wn-1i*wd)*t))+sqrt(1-(wd/wn)^2)*wn/wd*1/2i*(exp((-sqrt(1-(wd/wn)^2)*wn+1i*wd)*t)-exp((-sqrt(1-(wd/wn)^2)*wn-1i*wd)*t)), wd, 0);
expand(simplify(r))