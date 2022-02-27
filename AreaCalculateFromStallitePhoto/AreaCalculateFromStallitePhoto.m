%HASAN GÜNDÜZ 2150654802 Elektronik ve Haberleþme Mühendisliði(iö)
function uydu_fotografindan_alan_h()
% Bu kodlar ile mekansal kalibrasyon yapacaðýz.
% Görüntünüzü uzaysal olarak  kalibre ettikten sonra ,mesafe veya alan
% ölçümü  yapabilirsiniz.

global originalImage;
% Kullanýcýnýn Görüntü Ýþleme Araç Kutusu yüklü olduðunu kontrol edin.
clc;    % Komut penceresini temizleyin.
close all;  % Tüm iþlemleri kapat (görüntü aracý hariç.(imtool))
workspace;  % Çalýþma alaný panelinin gösterildiðinden emin olun.
format long g;
format compact;
fontSize = 20;

hasIPT = license('test', 'image_toolbox');
if ~hasIPT
	% Kullanýcýnýn araç kutusu yüklü deðil.
	message = sprintf('Afedersiniz,ancak Görüntü Ýþleme Araç Kutusunuz yok gibi görünüyor.\nYine de devam etmeyi denemek ister misin?');
	reply = questdlg(message, 'Toolbox missing', 'Yes', 'No', 'Yes');
	if strcmpi(reply, 'No')
		% Kullanýcý Hayýr derse, bu yüzden çýk.
		return;
	end
end

% Standart MATLAB gri tonlamalý demo görüntüsünde okuyun..
folder = fullfile(matlabroot, '\toolbox\images\imdemos');
button = menu('Hangi görüntüyü kullanýcaksýn?', 'iþlenmek istenilen görüntü..', 'Ýptal et');
switch button
case 1
		% Kullanýcýnýn kullanmak istediði dosyanýn adýný alýn.
		defaultFileName = fullfile(cd, '*.*');
		[baseFileName, folder] = uigetfile(defaultFileName, 'C:\ha.jpeg');
		if baseFileName == 0
			% Kullanýcý Ýptal düðmesini týkladý.
			return;
		end
	case 2
		return;
end

% Yolun sonuna eklenmiþ olarak tam dosya adýný alýn.
fullFileName = fullfile(folder, baseFileName);
% Dosyanýn var olup olmadýðýný kontrol edin.
if ~exist(fullFileName, 'file')
	% Dosya mevcut deðil - orada bulamadý. Bunun için arama yolunu kontrol edin.
	fullFileName = baseFileName; % No path this time.
	if ~exist(fullFileName, 'file')
		% Hala bulamadým. Kullanýcýyý uyar.
		errorMessage = sprintf('hata: %s arama yolu klasörde yok.', fullFileName);
		uiwait(warndlg(errorMessage));
		return;
	end
end
% Seçilen standart MATLAB demo görüntüsünü okuyun.
originalImage = imread(fullFileName);
%Görüntünün boyutlarýný öðrenin.
% numberOfColorBands = 1 olmalýdýr.
[~, columns numberOfColorBands] = size(originalImage);
% Orijinal gri tonlamalý resmi görüntüleyin.
figureHandle = figure;
subplot(1,2, 1);
imshow(originalImage, []);
axis on;
title('Original Grayscale Image', 'FontSize', fontSize);
%Rakamý tam ekrana büyütün.
set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
% Baþlýk çubuðuna bir ad verin.
set(gcf,'name','Demo by ImageAnalyst','numbertitle','off')

message = sprintf('Ýlk önce mekansal kalibrasyon yapacaksýnýz.');
reply = questdlg(message, 'Mekansal olarak kalibre edin', 'tamam', 'iptal et', 'tamam');
if strcmpi(reply, 'iptal et')
	% kullanýcý Hayýr derse ,çýk.
	return;
end
button = 1; % Döngü girmesine izin ver.

while button ~= 4
	if button > 1
		% Kalibrasyon yaptýktan sonra görevi seçmelerine izin verin.
		button = menu('Bir görev seçin', 'Kalibre et', 'Mesafe Ölçme', 'alan ölçmek', 'Demodan Çýk');
	end
	switch button
		case 1
			success = Calibrate();
			%Doðru týklamadýlarsa denemeye devam edin.
			while ~success
				success = Calibrate();
			end
			%   Eðer buraya gelirlerse, doðru týkladýlar
			% Baþka bir þeye geçin, böylece onlara soracak
			% görev için bir sonraki seferde döngü boyunca.
			button = 99;
		case 2
			DrawLine();
		case 3
			DrawArea();
		otherwise
			close(figureHandle);
			break;
	end
end

end

function success = Calibrate()
global lastDrawnHandle;
global calibration;
try
	success = false;
	instructions = sprintf('Satýrýn ilk uç noktasýný tutturmak için sol týklayýn. \ Satýrýn ikinci uç noktasýný tutturmak için sað týklayýn veya çift týklayýn. \ Ve Bundan sonra hattýn gerçek dünya mesafesini isteyeceðim.');
	title(instructions);
	msgboxw(instructions);

	[~, ~, rgbValues, xi,yi] = improfile(1000);
	% Deðerler 1000x1x3'tür. Singleton boyutundan kurtulmak ve 1000x3 yapmak için Squeeze'i arayýn.
	rgbValues = squeeze(rgbValues);
	distanceInPixels = sqrt( (xi(2)-xi(1)).^2 + (yi(2)-yi(1)).^2);
	if length(xi) < 2
		return;
	end
	% Plot the line.
	hold on;
	lastDrawnHandle = plot(xi, yi, 'y-', 'LineWidth', 2);

	% Ask the user for the real-world distance.
	userPrompt = {'Gerçek dünya birimlerini girin (örn. Mikron(mikrometre)): ',' Bu birimlerdeki mesafeyi girin:'};
	dialogTitle = 'Kalibrasyon bilgilerini belirtme';
	numberOfLines = 1;
	def = {' meters', '600'};
	answer = inputdlg(userPrompt, dialogTitle, numberOfLines, def);
	if isempty(answer)
		return;
	end
	calibration.units = answer{1};
	calibration.distanceInPixels = distanceInPixels;
	calibration.distanceInUnits = str2double(answer{2});
	calibration.distancePerPixel = calibration.distanceInUnits / distanceInPixels;
	success = true;
	
	message = sprintf('Çizdiðiniz mesafe %.2f pixels = %f %s dir.\nPiksel baþýna %s sayýsý %f dir .\n %s basýna düþen piksel sayýsý %f dir ' ,...
		distanceInPixels, calibration.distanceInUnits, calibration.units, ...
		calibration.units, calibration.distancePerPixel, ...
		calibration.units, 1/calibration.distancePerPixel);
	uiwait(msgbox(message));
catch ME
	errorMessage = sprintf('Kalibrasyon fonksiyonunda hata().\nÖnce sol týkladýktan sonra sað týkladýnýz mý?\n\nhata mesajý:\n%s', ME.message);
	fprintf(1, '%s\n', errorMessage);
	WarnUser(errorMessage);
end

return;	% Kalibre et
end

%=====================================================================
% --- DrawLine'da tuþa basma iþlemini gerçekleþtirir.
function success = DrawLine()
try
	global lastDrawnHandle;
	global calibration;
	fontSize = 14;
	
	instructions = sprintf('Bir çizgi çiz.\nÝlk olarak, satýrýn ilk uç noktasýný tutturmak için sol týklayýn.\nSatýrýn ikinci uç noktasýný tutturmak için sað týklayýn veya çift sol týklayýn.\n\nBundan sonra hattýn gerçek dünya mesafesini isteyeceðim.');
	title(instructions);
	msgboxw(instructions);
	subplot(1,2, 1); % Görüntü eksenlerine geçin.
	[cx,cy, rgbValues, xi,yi] = improfile(1000);
	% Profili tekrar alýn, ancak 1000 örnek yerine piksel sayýsýna aralýk býrakýn.
	hImage = findobj(gca,'Type','image');
	theImage = get(hImage, 'CData');
	lineLength = round(sqrt((xi(1)-xi(2))^2 + (yi(1)-yi(2))^2))
	[cx,cy, rgbValues] = improfile(theImage, xi, yi, lineLength);
	
	% Deðerler 1000x1x3'tür. Singleton boyutundan kurtulmak ve 1000x3 yapmak için Squeeze'i arayýn.
	rgbValues = squeeze(rgbValues);
	distanceInPixels = sqrt( (xi(2)-xi(1)).^2 + (yi(2)-yi(1)).^2);
	distanceInRealUnits = distanceInPixels * calibration.distancePerPixel;
	
	if length(xi) < 2
		return;
	end
	% Çizgiyi çizin.
	hold on;
	lastDrawnHandle = plot(xi, yi, 'y-', 'LineWidth', 2);
	
	% Profilleri kýrmýzý, yeþil ve mavi bileþenlerin çizgisi boyunca çizin.
	subplot(1,2,2);
	[rows, columns] = size(rgbValues);
	if columns == 3
		% Bu bir RGB görüntüsü.
		plot(rgbValues(:, 1), 'r-', 'LineWidth', 2);
		hold on;
		plot(rgbValues(:, 2), 'g-', 'LineWidth', 2);
		plot(rgbValues(:, 3), 'b-', 'LineWidth', 2);
		title('Red, Green, and Blue Profiles along the line you just drew.', 'FontSize', 14);
	else
		% Gri tonlamalý bir görüntü.
		plot(rgbValues, 'k-', 'LineWidth', 2);
	end
	xlabel('X', 'FontSize', fontSize);
	ylabel('Gray Level', 'FontSize', fontSize);
	title('Intensity Profile', 'FontSize', fontSize);
	grid on;
	
	%Bir iletiþim kutusu aracýlýðýyla kullaným.
	txtInfo = sprintf('Distance = %.1f %s, which = %.1f pixels.', ...
		distanceInRealUnits, calibration.units, distanceInPixels);
	msgboxw(txtInfo);
	% Deðerleri komut penceresine yazdýrýn.
	fprintf(1, '%\n', txtInfo);
	
catch ME
	errorMessage = sprintf('Error in function DrawLine().\n\nhata mesajý:\n%s', ME.message);
	fprintf(1, '%s\n', errorMessage);
	WarnUser(errorMessage);
end
end  % DrawLine() çýkýþlý

%=====================================================================
function DrawArea()
global originalImage;
global lastDrawnHandle;
global calibration;
try
	txtInfo = sprintf('Köþeleri tutturmak için sol týklayýnýz.\nPoligonun son noktasýný tutturmak için çift sol týklama.');
	title(txtInfo);
	msgboxw(txtInfo);
	
	% Boyut bilgisi alýn.
	[rows, columns, numberOfColorBands] = size(originalImage);
	
	% Gri tonlamalý bir sürüm alýn.
	if numberOfColorBands > 1
		grayImage = rgb2gray(originalImage);
	else
		grayImage = originalImage;
	end
	
	subplot(1,2, 1); % Görüntü eksenlerine geçin.
	% Kullanýcýdan bir çokgen çizmesini isteyin.
	[maskImage, xi, yi] = roipolyold();
	
	% Çokgeni ana ekrandaki görüntünün üzerine çizin.
	hold on;
	lastDrawnHandle = plot(xi, yi, 'r-', 'LineWidth', 2);
	numberOfPixels = sum(maskImage(:));
	area = numberOfPixels * calibration.distancePerPixel^2;
	
	% Gri tonlamalý görüntünün ortalama gri seviyesini elde edin.
	mean_GL = mean(grayImage(maskImage)); % Gri tonlama sürümü.

	% Alan deðerlerini komut penceresine yazdýrýn.
	txtInfo = sprintf('Alan = %8.1f square %s.\nMean gray level = %.2f.', ...
		area, calibration.units, mean_GL);
	fprintf(1,'%s\n', txtInfo);
	title(txtInfo, 'FontSize', 14);

	% Alan ölçümü ile yapýlýr.
	% Þimdi, sadece eðlence için, ortalama deðeri alýn ve histogramý görüntüleyin.
	if numberOfColorBands >= 3
		% Renkli bir görüntü. Ortalama RGB Deðerlerini alýn.
		redPlane = double(originalImage(:, :, 1));
		greenPlane = double(originalImage(:, :, 2));
		bluePlane = double(originalImage(:, :, 3));
		mean_RGB_GL(1) = mean(redPlane(maskImage));
		mean_RGB_GL(2) = mean(greenPlane(maskImage));
		mean_RGB_GL(3) = mean(bluePlane(maskImage));
		fprintf('%s\nRed mean = %.2f\nGreen mean = %.2f\nBlue mean = %.2f', ...
			txtInfo, mean_RGB_GL(1), mean_RGB_GL(2), mean_RGB_GL(3));
	end	
	
	% Sadece eðlence için, histogramýný maskeli bölge içine alalým.
	[pixelCount, grayLevels] = imhist(grayImage(maskImage));
	subplot(1,2, 2); % Eksenleri çizmeye geç.
	cla;
	bar(pixelCount);
	grid on;
	caption = sprintf('Histogram within area.    Mean gray level = %.2f', mean_GL);
	title(caption, 'FontSize', 14);
	xlim([0 grayLevels(end)]); % X eksenini manuel olarak ölçeklendirme.
	% Ortalamayý histogramda dikey kýrmýzý çubuk olarak göster.
	hold on;
	maxYValue = ylim;
	line([mean_GL, mean_GL], [0 maxYValue(2)], 'Color', 'r', 'linewidth', 2);
catch ME
	errorMessage = sprintf('Error in function DrawArea().\n\nhata mesajý:\n%s', ME.message);
	fprintf(1, '%s\n', errorMessage);
	WarnUser(errorMessage);
end

end % yazar: DrawArea()


function msgboxw(message)
	uiwait(msgbox(message));
end

function WarnUser(message)
	uiwait(msgbox(message));
end