%% Fit a 2D gaussian function to data

% Uses lsqcurvefit to fit
%
% INPUT:
% 
%   MdataSize: Size of nxn data matrix
%   x0 = [Amp,x0,wx,y0,wy,fi]: Inital guess parameters
%   x = [Amp,x0,wx,y0,wy,fi]: simulated centroid parameters
%   noise: noise in % of centroid peak value (x(1)

%% ---------User Input---------------------
[rows, columns] = size(cdata);
MdataSize = rows; % Size of nxn data matrix
temp = rows / 2;
[M,I] = max(cdata(:));
[I_row, I_col] = ind2sub (size(cdata), I)
if eq (rem (MdataSize, 2), 0.0)
    x_ = double ([-temp + 1 : temp]);
    I_row = I_row - MdataSize / 2;
    I_col = I_col - MdataSize / 2;


else
    temp2 = floor (temp);
    x_ = double ([ceil(-temp) : temp2]);
    I_row = I_row - ceil(MdataSize / 2);
    I_col = I_col - ceil(MdataSize / 2);
end

y_ = x_;


% parameters are: [Amplitude, x0, sigmax, y0, sigmay, angel(in rad)]
x0 = double ([M, I_col, 2.0, I_row, 2.0, 0.0]); %Inital guess parameters
x = x0; %[4,2.2,7,3.4,4.5,+0.02*2*pi]; %centroid parameters
noise = 0;
InterpolationMethod = 'cubic'; % 'nearest','linear','spline','cubic'
FitForOrientation = 0; % 0: fit for orientation. 1: do not fit for orientation

%% ---Generate centroid to be fitted--------------------------------------
xin = x; 
noise = noise/100 * x(1);
[X,Y] = meshgrid (x_, y_);%meshgrid(-MdataSize/2:MdataSize/2);
xdata = zeros(size(X,1),size(Y,2),2);
xdata(:,:,1) = X;
xdata(:,:,2) = Y;
[Xhr,Yhr] = meshgrid(linspace(-MdataSize/2,MdataSize/2,300)); % generate high res grid for plot
xdatahr = zeros(300,300,2);
xdatahr(:,:,1) = Xhr;
xdatahr(:,:,2) = Yhr;

Z = double (cdata);

%% --- Fit---------------------
if FitForOrientation == 0
    % define lower and upper bounds [Amp,xo,wx,yo,wy,fi]
    lb = [0,-MdataSize/2,0,-MdataSize/2,0,-pi/4];
    ub = [realmax('double'),MdataSize/2,(MdataSize/2)^2,MdataSize/2,(MdataSize/2)^2,pi/4];
    [x,resnorm,residual,exitflag] = lsqcurvefit(@D2GaussFunctionRot,x0,xdata,Z,lb,ub);
else
    x0 =x0(1:5);
    xin(6) = 0; 
    x =x(1:5);
    lb = [0,-MdataSize/2,0,-MdataSize/2,0];
    ub = [realmax('double'),MdataSize/2,(MdataSize/2)^2,MdataSize/2,(MdataSize/2)^2];
    [x,resnorm,residual,exitflag] = lsqcurvefit(@D2GaussFunction,x0,xdata,Z,lb,ub);
    x(6) = 0;
end

%% ---------Plot 3D Image-------------
figure(1)
C = del2(Z);
mesh(X,Y,Z,C) %plot data
hold on
surfc(Xhr,Yhr,D2GaussFunctionRot(x,xdatahr),'EdgeColor','none') %plot fit
axis([-MdataSize/2-0.5 MdataSize/2+0.5 -MdataSize/2-0.5 MdataSize/2+0.5 -noise noise+x(1)])
alpha(0.2)  
hold off

%% -----Plot profiles----------------
hf2 = figure(2);
set(hf2, 'Position', [20 20 950 900])
alpha(0)
subplot(4,4, [5,6,7,9,10,11,13,14,15])
imagesc(X(1,:),Y(:,1)',Z)
set(gca,'YDir','reverse')
colormap('jet')

string1 = ['       Amplitude','    X-Coordinate','    Y-Coordinate'];%'     Angle'];
string2 = ['Set     ',num2str(xin(1), '% 100.3f'),'             ',num2str(xin(2), '% 100.3f'),'         ',num2str(xin(4), '% 100.3f')];%,'     ',num2str(xin(6), '% 100.3f')];
string3 = ['Fit      ',num2str(x(1), '% 100.3f'),'             ',num2str(x(2), '% 100.3f'),'         ',num2str(x(4), '% 100.3f')];%,'     ',num2str(x(6), '% 100.3f')];

text(-MdataSize/2*0.9,+MdataSize/2*1.15,string1,'Color','red')
text(-MdataSize/2*0.9,+MdataSize/2*1.2,string2,'Color','red')
text(-MdataSize/2*0.9,+MdataSize/2*1.25,string3,'Color','red')

%% -----Calculate cross sections-------------
% generate points along horizontal axis
m = -tan(x(6));% Point slope formula
b = (-m*x(2) + x(4));
xvh = -MdataSize/2:MdataSize/2;
yvh = xvh*m + b;
hPoints = interp2(X,Y,Z,xvh,yvh,InterpolationMethod);
% generate points along vertical axis
mrot = -m;
brot = (mrot*x(4) - x(2));
yvv = -MdataSize/2:MdataSize/2;
xvv = yvv*mrot - brot;
vPoints = interp2(X,Y,Z,xvv,yvv,InterpolationMethod);

hold on % Indicate major and minor axis on plot

% plot lins 
plot([xvh(1) xvh(size(xvh))],[yvh(1) yvh(size(yvh))],'r') 
plot([xvv(1) xvv(size(xvv))],[yvv(1) yvv(size(yvv))],'g') 

hold off
axis([-MdataSize/2-0.5 MdataSize/2+0.5 -MdataSize/2-0.5 MdataSize/2+0.5])
%%

ymin = - noise * x(1);
ymax = x(1)*(1+noise);
xdatafit = linspace(-MdataSize/2-0.5,MdataSize/2+0.5,300);
hdatafit = x(1)*exp(-(xdatafit-x(2)).^2/(2*x(3)^2));
vdatafit = x(1)*exp(-(xdatafit-x(4)).^2/(2*x(5)^2));
subplot(4,4, [1:3])
xposh = (xvh-x(2))/cos(x(6))+x(2);% correct for the longer diagonal if fi~=0
plot(xposh,hPoints,'r.',xdatafit,hdatafit,'black')
axis([-MdataSize/2-0.5 MdataSize/2+0.5 ymin*1.1 ymax*1.1])
subplot(4,4,[8,12,16])
xposv = (yvv-x(4))/cos(x(6))+x(4);% correct for the longer diagonal if fi~=0
plot(vPoints,xposv,'g.',vdatafit,xdatafit,'black')
axis([ymin*1.1 ymax*1.1 -MdataSize/2-0.5 MdataSize/2+0.5])
set(gca,'YDir', 'reverse')
figure(gcf) % bring current figure to front



 
