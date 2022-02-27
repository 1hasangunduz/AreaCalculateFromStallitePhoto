%HASAN G�ND�Z 2150654802 Elektronik ve Haberle�me M�hendisli�i(i�)
function uydu_fotografindan_alan_h()
% Bu kodlar ile mekansal kalibrasyon yapaca��z.
% G�r�nt�n�z� uzaysal olarak  kalibre ettikten sonra ,mesafe veya alan
% �l��m�  yapabilirsiniz.

global originalImage;
% Kullan�c�n�n G�r�nt� ��leme Ara� Kutusu y�kl� oldu�unu kontrol edin.
clc;    % Komut penceresini temizleyin.
close all;  % T�m i�lemleri kapat (g�r�nt� arac� hari�.(imtool))
workspace;  % �al��ma alan� panelinin g�sterildi�inden emin olun.
format long g;
format compact;
fontSize = 20;

hasIPT = license('test', 'image_toolbox');
if ~hasIPT
	% Kullan�c�n�n ara� kutusu y�kl� de�il.
	message = sprintf('Afedersiniz,ancak G�r�nt� ��leme Ara� Kutusunuz yok gibi g�r�n�yor.\nYine de devam etmeyi denemek ister misin?');
	reply = questdlg(message, 'Toolbox missing', 'Yes', 'No', 'Yes');
	if strcmpi(reply, 'No')
		% Kullan�c� Hay�r derse, bu y�zden ��k.
		return;
	end
end

% Standart MATLAB gri tonlamal� demo g�r�nt�s�nde okuyun..
folder = fullfile(matlabroot, '\toolbox\images\imdemos');
button = menu('Hangi g�r�nt�y� kullan�caks�n?', 'i�lenmek istenilen g�r�nt�..', '�ptal et');
switch button
case 1
		% Kullan�c�n�n kullanmak istedi�i dosyan�n ad�n� al�n.
		defaultFileName = fullfile(cd, '*.*');
		[baseFileName, folder] = uigetfile(defaultFileName, 'C:\ha.jpeg');
		if baseFileName == 0
			% Kullan�c� �ptal d��mesini t�klad�.
			return;
		end
	case 2
		return;
end

% Yolun sonuna eklenmi� olarak tam dosya ad�n� al�n.
fullFileName = fullfile(folder, baseFileName);
% Dosyan�n var olup olmad���n� kontrol edin.
if ~exist(fullFileName, 'file')
	% Dosya mevcut de�il - orada bulamad�. Bunun i�in arama yolunu kontrol edin.
	fullFileName = baseFileName; % No path this time.
	if ~exist(fullFileName, 'file')
		% Hala bulamad�m. Kullan�c�y� uyar.
		errorMessage = sprintf('hata: %s arama yolu klas�rde yok.', fullFileName);
		uiwait(warndlg(errorMessage));
		return;
	end
end
% Se�ilen standart MATLAB demo g�r�nt�s�n� okuyun.
originalImage = imread(fullFileName);
%G�r�nt�n�n boyutlar�n� ��renin.
% numberOfColorBands = 1 olmal�d�r.
[~, columns numberOfColorBands] = size(originalImage);
% Orijinal gri tonlamal� resmi g�r�nt�leyin.
figureHandle = figure;
subplot(1,2, 1);
imshow(originalImage, []);
axis on;
title('Original Grayscale Image', 'FontSize', fontSize);
%Rakam� tam ekrana b�y�t�n.
set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
% Ba�l�k �ubu�una bir ad verin.
set(gcf,'name','Demo by ImageAnalyst','numbertitle','off')

message = sprintf('�lk �nce mekansal kalibrasyon yapacaks�n�z.');
reply = questdlg(message, 'Mekansal olarak kalibre edin', 'tamam', 'iptal et', 'tamam');
if strcmpi(reply, 'iptal et')
	% kullan�c� Hay�r derse ,��k.
	return;
end
button = 1; % D�ng� girmesine izin ver.

while button ~= 4
	if button > 1
		% Kalibrasyon yapt�ktan sonra g�revi se�melerine izin verin.
		button = menu('Bir g�rev se�in', 'Kalibre et', 'Mesafe �l�me', 'alan �l�mek', 'Demodan ��k');
	end
	switch button
		case 1
			success = Calibrate();
			%Do�ru t�klamad�larsa denemeye devam edin.
			while ~success
				success = Calibrate();
			end
			%   E�er buraya gelirlerse, do�ru t�klad�lar
			% Ba�ka bir �eye ge�in, b�ylece onlara soracak
			% g�rev i�in bir sonraki seferde d�ng� boyunca.
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
	instructions = sprintf('Sat�r�n ilk u� noktas�n� tutturmak i�in sol t�klay�n. \ Sat�r�n ikinci u� noktas�n� tutturmak i�in sa� t�klay�n veya �ift t�klay�n. \ Ve Bundan sonra hatt�n ger�ek d�nya mesafesini isteyece�im.');
	title(instructions);
	msgboxw(instructions);

	[~, ~, rgbValues, xi,yi] = improfile(1000);
	% De�erler 1000x1x3't�r. Singleton boyutundan kurtulmak ve 1000x3 yapmak i�in Squeeze'i aray�n.
	rgbValues = squeeze(rgbValues);
	distanceInPixels = sqrt( (xi(2)-xi(1)).^2 + (yi(2)-yi(1)).^2);
	if length(xi) < 2
		return;
	end
	% Plot the line.
	hold on;
	lastDrawnHandle = plot(xi, yi, 'y-', 'LineWidth', 2);

	% Ask the user for the real-world distance.
	userPrompt = {'Ger�ek d�nya birimlerini girin (�rn. Mikron(mikrometre)): ',' Bu birimlerdeki mesafeyi girin:'};
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
	
	message = sprintf('�izdi�iniz mesafe %.2f pixels = %f %s dir.\nPiksel ba��na %s say�s� %f dir .\n %s bas�na d��en piksel say�s� %f dir ' ,...
		distanceInPixels, calibration.distanceInUnits, calibration.units, ...
		calibration.units, calibration.distancePerPixel, ...
		calibration.units, 1/calibration.distancePerPixel);
	uiwait(msgbox(message));
catch ME
	errorMessage = sprintf('Kalibrasyon fonksiyonunda hata().\n�nce sol t�klad�ktan sonra sa� t�klad�n�z m�?\n\nhata mesaj�:\n%s', ME.message);
	fprintf(1, '%s\n', errorMessage);
	WarnUser(errorMessage);
end

return;	% Kalibre et
end

%=====================================================================
% --- DrawLine'da tu�a basma i�lemini ger�ekle�tirir.
function success = DrawLine()
try
	global lastDrawnHandle;
	global calibration;
	fontSize = 14;
	
	instructions = sprintf('Bir �izgi �iz.\n�lk olarak, sat�r�n ilk u� noktas�n� tutturmak i�in sol t�klay�n.\nSat�r�n ikinci u� noktas�n� tutturmak i�in sa� t�klay�n veya �ift sol t�klay�n.\n\nBundan sonra hatt�n ger�ek d�nya mesafesini isteyece�im.');
	title(instructions);
	msgboxw(instructions);
	subplot(1,2, 1); % G�r�nt� eksenlerine ge�in.
	[cx,cy, rgbValues, xi,yi] = improfile(1000);
	% Profili tekrar al�n, ancak 1000 �rnek yerine piksel say�s�na aral�k b�rak�n.
	hImage = findobj(gca,'Type','image');
	theImage = get(hImage, 'CData');
	lineLength = round(sqrt((xi(1)-xi(2))^2 + (yi(1)-yi(2))^2))
	[cx,cy, rgbValues] = improfile(theImage, xi, yi, lineLength);
	
	% De�erler 1000x1x3't�r. Singleton boyutundan kurtulmak ve 1000x3 yapmak i�in Squeeze'i aray�n.
	rgbValues = squeeze(rgbValues);
	distanceInPixels = sqrt( (xi(2)-xi(1)).^2 + (yi(2)-yi(1)).^2);
	distanceInRealUnits = distanceInPixels * calibration.distancePerPixel;
	
	if length(xi) < 2
		return;
	end
	% �izgiyi �izin.
	hold on;
	lastDrawnHandle = plot(xi, yi, 'y-', 'LineWidth', 2);
	
	% Profilleri k�rm�z�, ye�il ve mavi bile�enlerin �izgisi boyunca �izin.
	subplot(1,2,2);
	[rows, columns] = size(rgbValues);
	if columns == 3
		% Bu bir RGB g�r�nt�s�.
		plot(rgbValues(:, 1), 'r-', 'LineWidth', 2);
		hold on;
		plot(rgbValues(:, 2), 'g-', 'LineWidth', 2);
		plot(rgbValues(:, 3), 'b-', 'LineWidth', 2);
		title('Red, Green, and Blue Profiles along the line you just drew.', 'FontSize', 14);
	else
		% Gri tonlamal� bir g�r�nt�.
		plot(rgbValues, 'k-', 'LineWidth', 2);
	end
	xlabel('X', 'FontSize', fontSize);
	ylabel('Gray Level', 'FontSize', fontSize);
	title('Intensity Profile', 'FontSize', fontSize);
	grid on;
	
	%Bir ileti�im kutusu arac�l���yla kullan�m.
	txtInfo = sprintf('Distance = %.1f %s, which = %.1f pixels.', ...
		distanceInRealUnits, calibration.units, distanceInPixels);
	msgboxw(txtInfo);
	% De�erleri komut penceresine yazd�r�n.
	fprintf(1, '%\n', txtInfo);
	
catch ME
	errorMessage = sprintf('Error in function DrawLine().\n\nhata mesaj�:\n%s', ME.message);
	fprintf(1, '%s\n', errorMessage);
	WarnUser(errorMessage);
end
end  % DrawLine() ��k��l�

%=====================================================================
function DrawArea()
global originalImage;
global lastDrawnHandle;
global calibration;
try
	txtInfo = sprintf('K��eleri tutturmak i�in sol t�klay�n�z.\nPoligonun son noktas�n� tutturmak i�in �ift sol t�klama.');
	title(txtInfo);
	msgboxw(txtInfo);
	
	% Boyut bilgisi al�n.
	[rows, columns, numberOfColorBands] = size(originalImage);
	
	% Gri tonlamal� bir s�r�m al�n.
	if numberOfColorBands > 1
		grayImage = rgb2gray(originalImage);
	else
		grayImage = originalImage;
	end
	
	subplot(1,2, 1); % G�r�nt� eksenlerine ge�in.
	% Kullan�c�dan bir �okgen �izmesini isteyin.
	[maskImage, xi, yi] = roipolyold();
	
	% �okgeni ana ekrandaki g�r�nt�n�n �zerine �izin.
	hold on;
	lastDrawnHandle = plot(xi, yi, 'r-', 'LineWidth', 2);
	numberOfPixels = sum(maskImage(:));
	area = numberOfPixels * calibration.distancePerPixel^2;
	
	% Gri tonlamal� g�r�nt�n�n ortalama gri seviyesini elde edin.
	mean_GL = mean(grayImage(maskImage)); % Gri tonlama s�r�m�.

	% Alan de�erlerini komut penceresine yazd�r�n.
	txtInfo = sprintf('Alan = %8.1f square %s.\nMean gray level = %.2f.', ...
		area, calibration.units, mean_GL);
	fprintf(1,'%s\n', txtInfo);
	title(txtInfo, 'FontSize', 14);

	% Alan �l��m� ile yap�l�r.
	% �imdi, sadece e�lence i�in, ortalama de�eri al�n ve histogram� g�r�nt�leyin.
	if numberOfColorBands >= 3
		% Renkli bir g�r�nt�. Ortalama RGB De�erlerini al�n.
		redPlane = double(originalImage(:, :, 1));
		greenPlane = double(originalImage(:, :, 2));
		bluePlane = double(originalImage(:, :, 3));
		mean_RGB_GL(1) = mean(redPlane(maskImage));
		mean_RGB_GL(2) = mean(greenPlane(maskImage));
		mean_RGB_GL(3) = mean(bluePlane(maskImage));
		fprintf('%s\nRed mean = %.2f\nGreen mean = %.2f\nBlue mean = %.2f', ...
			txtInfo, mean_RGB_GL(1), mean_RGB_GL(2), mean_RGB_GL(3));
	end	
	
	% Sadece e�lence i�in, histogram�n� maskeli b�lge i�ine alal�m.
	[pixelCount, grayLevels] = imhist(grayImage(maskImage));
	subplot(1,2, 2); % Eksenleri �izmeye ge�.
	cla;
	bar(pixelCount);
	grid on;
	caption = sprintf('Histogram within area.    Mean gray level = %.2f', mean_GL);
	title(caption, 'FontSize', 14);
	xlim([0 grayLevels(end)]); % X eksenini manuel olarak �l�eklendirme.
	% Ortalamay� histogramda dikey k�rm�z� �ubuk olarak g�ster.
	hold on;
	maxYValue = ylim;
	line([mean_GL, mean_GL], [0 maxYValue(2)], 'Color', 'r', 'linewidth', 2);
catch ME
	errorMessage = sprintf('Error in function DrawArea().\n\nhata mesaj�:\n%s', ME.message);
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