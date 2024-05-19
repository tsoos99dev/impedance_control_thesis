function st = settling_time(z, w0, tol)
    if z < 0.98
        st = -log((1-tol)*sqrt(1-z^2))/(z*w0);
    elseif z > 1.03
        st = log(2*(1-tol)*sqrt(z^2-1)/(z+sqrt(z^2-1)))/((-z+sqrt(z^2-1))*w0);
    else
        st = -(lambertw(-1, -(1-tol)/exp(1))+1)/w0+1.5*(z-1)/w0;
    end
end