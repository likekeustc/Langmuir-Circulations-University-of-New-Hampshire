clear all
close all
clc

% M: number of Y domain division
% N: number of Z domain division

N=64;
M=64;
% Z from -1 to 1. Chebyshev
% Y from 0 to 2*pi FFT
La_t=1;
epsilon=1;
La=0.01;
k=2;
Z=cos((0:N)'.*pi/N);
Y=(0:M-1)'.*(2.0*pi)/M;
q=2/3;
delta_t=5*10^(-4); % nondimentional time steps
n=[0:M/2-1 0 -M/2+1:-1];

Hhat=1;
zeta=2;
xi=2;
uR=M/xi;% B.C. on u: du/dZ=1/xi |  Z=+1,-1
TR=0;
for jj=1:M
    for ii=1:N+1
        vs(ii,jj)=0;
    end
end
%calculate coeffFT=1/delta_t+n^2*zeta^2/(4*sigma)    
for jj=1:M
    for kk=1:2 
            coeffFT(kk,jj)=2/(La*xi^2)*(1/delta_t+La*zeta^2*n(jj)^2/2); 
            coeff(kk,jj)=2/(La*xi^2)*(1/delta_t-La*zeta^2*n(jj)^2/2); 
    end
end
    

% define the filed of Psi and U
for ii=1:N+1
    for jj=1:M
        Psiini(ii,jj)=sin(k*(Y(jj)-2*pi)/zeta)*cos(pi*Z(ii)/2);
        Tini(ii,jj)=0;
        uini(ii,jj)=-(Z(ii)-1)/xi;
    end
end
%Because: Omega=-(Psi_YY+Psi_ZZ) holds everywhere including initial
%conditions
for ii=1:N+1
    Psiini_Y(ii,:)=ffdfft(Psiini(ii,:));
    Psiini_YY(ii,:)=ffdfft(Psiini_Y(ii,:));
end
for jj=1:M
    Psiini_Z(:,jj)=chedfft(Psiini(:,jj));
    Psiini_ZZ(:,jj)=chedfft(Psiini_Z(:,jj));
end
Omegaini=-Psiini_YY-Psiini_ZZ;
%suppose we know Tini, uini, Omegaini, and Psiini at t=0 (initial condition)
Tcur=Tini;
Told=Tini;

ucur=uini;
uold=uini;

Omegacur=Omegaini;
Omegaold=Omegaini;

Psicur=Psiini;
Psiold=Psiini;

% Initialization of Funew FTnew FOmeganew FPsinew
Funew=zeros(1+N, M);
FTnew=zeros(1+N, M);
FOmeganew=zeros(1+N, M);
FPsinew=zeros(1+N, M);
%calculate y velocity and z velocity
for ii=1:N+1
    wcur(ii,:)=-zeta*ffdfft(Psicur(ii,:));
end
for jj=1:M
    vcur(:,jj)=xi*chedfft(Psicur(:,jj));
end

subplot(2,2,1),contour(Y,Z,vcur),title('y velocity')
subplot(2,2,2),contour(Y,Z,ucur),title('u velocity')
subplot(2,2,3),contour(Y,Z,Omegacur),title('Omega')
subplot(2,2,4),contour(Y,Z,wcur),title('z velocity')

pause,
for kk=1:4000
    t=kk*delta_t
% calculate G_u G_T and GOmega in current and old time steps    
    G_uold=Gu(Psiold, uold, vs, epsilon, zeta, xi, La_t, M, N);
    G_Told=zeros(N+1,M);
    G_Omegaold=GOmega(Psiold, Omegaold, Told, uold, vs, epsilon, zeta,...
    xi, La_t, M, N);
    G_ucur=Gu(Psicur, ucur, vs, epsilon, zeta, xi, La_t, M, N);
    G_Tcur=zeros(N+1,M);
    G_Omegacur=GOmega(Psicur, Omegacur, Tcur, ucur, vs, epsilon, zeta,...
    xi, La_t, M, N);
% FFT on Y direction for G series at current and old time steps and T Psi u
% Omega for current steps
    for ii=1:N+1
        FG_uold(ii,:)=fft(G_uold(ii,:));
        FG_Told(ii,:)=fft(G_Told(ii,:));
        FG_Omegaold(ii,:)=fft(G_Omegaold(ii,:));
        
        FG_ucur(ii,:)=fft(G_ucur(ii,:));
        FG_Tcur(ii,:)=fft(G_Tcur(ii,:));
        FG_Omegacur(ii,:)=fft(G_Omegacur(ii,:));
        
        FPsicur(ii,:)=fft(Psicur(ii,:));
        Fucur(ii,:)=fft(ucur(ii,:));
        FTcur(ii,:)=fft(Tcur(ii,:));
        FOmegacur(ii,:)=fft(Omegacur(ii,:));
    end
% differentiate FTcur two times on Z. The result is written as FTcur_ZZ. Do
% the same thing and get FOmegacur_ZZ and Fucur_ZZ.
% Remember, FTcur, Fucur and FOmegacur are all complex numbers but our
% function chedfft is only in real numbers, we have to use function both in
% real part and complex part.
    for jj=1:M
        FTcur_ZZ(:,jj)=chedfft(chedfft(real(FTcur(:,jj))))+...
            i*chedfft(chedfft(imag(FTcur(:,jj))));
        FOmegacur_ZZ(:,jj)=chedfft(chedfft(real(FOmegacur(:,jj))))+...
            i*chedfft(chedfft(imag(FOmegacur(:,jj))));
        Fucur_ZZ(:,jj)=chedfft(chedfft(real(Fucur(:,jj))))+...
            i*chedfft(chedfft(imag(Fucur(:,jj))));
    end

%Write down the right handside of the whole equation. Be prepared to solve
%Helmholtz equation.
    for jj=1:M
% equation for T        
        rightside_T(:,jj)=-coeff(1,jj)*FTcur(:,jj)-FTcur_ZZ(:,jj)...
            -0*(q*FG_Tcur(:,jj)+(1-q)*(FG_Told(:,jj)));
% equation for u        
        rightside_u(:,jj)=-coeff(2,jj)*Fucur(:,jj)-Fucur_ZZ(:,jj)...
            -2/(La*xi^2)*(q*FG_ucur(:,jj)+(1-q)*(FG_uold(:,jj))); 
% equation for Omega     
        rightside_Omega(:,jj)=-coeff(2,jj)*FOmegacur(:,jj)...
            -FOmegacur_ZZ(:,jj)-2/(La*xi^2)*...
            (q*FG_Omegacur(:,jj)+(1-q)*(FG_Omegaold(:,jj)));
    end
% Use helmholtzDf and helmholtz solver for the dirivative BC and direchlet
% BC.
% 1.Deal with dirivative BC with function "helmholtzDF"
%       u=helmholtzDF(N, f, lambda, R1, R2)
% Remember, both helmholtzDF and helmholtz are only available in real world
% not complex. Thus, we have to calculate real part and imaginary part
% separatedly.
    Funew_real(:,1)=helmholtzDF(N, real(rightside_u(:,1)), coeffFT(2,1), uR, uR);
    Funew_imag(:,1)=helmholtzDF(N, imag(rightside_u(:,1)), coeffFT(2,1), 0, 0);
    FTnew_real(:,1)=helmholtzDF(N, real(rightside_T(:,1)), coeffFT(1,1), TR, 0);
    FTnew_imag(:,1)=helmholtzDF(N, imag(rightside_T(:,1)), coeffFT(1,1), 0, 0);
    FOmeganew_real(:,1)=helmholtz(N, real(rightside_Omega(:,1)), coeffFT(2,1));
    FOmeganew_imag(:,1)=helmholtz(N, imag(rightside_Omega(:,1)), coeffFT(2,1));
    for jj=2:M
        Funew_real(:,jj)=helmholtzDF(N, real(rightside_u(:,jj)), coeffFT(2,jj), 0, 0);
        Funew_imag(:,jj)=helmholtzDF(N, imag(rightside_u(:,jj)), coeffFT(2,jj), 0, 0);
        FTnew_real(:,jj)=helmholtzDF(N, real(rightside_T(:,jj)), coeffFT(1,jj), 0, 0);
        FTnew_imag(:,jj)=helmholtzDF(N, imag(rightside_T(:,jj)), coeffFT(1,jj), 0, 0);
        FOmeganew_real(:,jj)=helmholtz(N, real(rightside_Omega(:,jj)), coeffFT(2,jj));
        FOmeganew_imag(:,jj)=helmholtz(N, imag(rightside_Omega(:,jj)), coeffFT(2,jj));
    end
    Funew=Funew_real+i*Funew_imag;
    FTnew=FTnew_real+i*FTnew_imag;
    FOmeganew=FOmeganew_real+i*FOmeganew_imag;
    
    
% The result is in FFT frequency space. Transform into physical space by
% IFFT
    for ii=1:N+1
        unew(ii,:)=(ifft(Funew(ii,:)));
        Tnew(ii,:)=(ifft(FTnew(ii,:)));
        Omeganew(ii,:)=(ifft(FOmeganew(ii,:)));
    end
    Psinew=possion(M,N,Omeganew,xi,zeta);


% Time steps marching program, be prepared to the next loop.
    uold=ucur;
    ucur=unew;
    Told=Tcur;
    Tcur=Tnew;
    Omegaold=Omegacur;
    Omegacur=Omeganew;
    Psiold=Psicur;
    Psicur=Psinew;
%calculate y velocity and z velocity
for ii=1:N+1
    wnew(ii,:)=-zeta*ffdfft(Psinew(ii,:));
end
for jj=1:M
    vnew(:,jj)=xi*chedfft(Psinew(:,jj));
end

      subaxis(1, 3, 1, 'Spacing', 0.05, 'Padding', 0, 'Margin', 0.12),
      imagesc(Y,Z,unew), title('x-velocity','FontSize',16),caxis([0, 1]),colorbar,
      xlabel('y','FontSize',14);
      ylabel('z','FontSize',14);
      subaxis(1, 3, 2, 'Spacing', 0.05, 'Padding', 0, 'Margin', 0.12),
      imagesc(Y,Z,Omeganew),title('x-vorticity','FontSize',16),caxis([-4, 4]),colorbar,
      xlabel('y','FontSize',14);
      subaxis(1, 3, 3, 'Spacing', 0.05, 'Padding', 0, 'Margin', 0.12),
      imagesc(Y,Z,Psinew),title('streamfunction','FontSize',16),caxis([-0.4, 0.4]),colorbar,
      xlabel('y','FontSize',14);

      set(gcf, 'PaperUnits', 'inches');
      x_width=15 ;y_width=4;
      set(gcf, 'PaperPosition', [0 0 x_width y_width]); %

if mod(kk, 50)==1
      fprintf(['kk = ', num2str(kk), '\n']);
      print(['fig_', num2str(kk), '.png'], '-dpng');
      close all;
end
%pause(.1),
error=[norm(unew-uold) norm(Tnew-Told) norm(Omeganew-Omegaold)...
    norm(Psinew-Psiold)]

end
 


