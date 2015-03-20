function varargout = darjanin(varargin)
% DARJANIN MATLAB code for darjanin.fig
%      DARJANIN, by itself, creates a new DARJANIN or raises the existing
%      singleton*.
%
%      H = DARJANIN returns the handle to a new DARJANIN or the handle to
%      the existing singleton*.
%
%      DARJANIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DARJANIN.M with the given input arguments.
%
%      DARJANIN('Property','Value',...) creates a new DARJANIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before darjanin_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to darjanin_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help darjanin

% Last Modified by GUIDE v2.5 20-Mar-2015 19:42:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @darjanin_OpeningFcn, ...
                   'gui_OutputFcn',  @darjanin_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before darjanin is made visible.
function darjanin_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to darjanin (see VARARGIN)

% Choose default command line output for darjanin
handles.output = hObject;
handles.database_loaded = false;
handles.image_loaded = false;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes darjanin wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = darjanin_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in load_image.
function load_image_Callback(hObject, eventdata, handles)
% hObject    handle to load_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[image_file, image_path_name] = uigetfile({'*.jpg', 'JPEG (*.jpg)'; '*.*', 'All files (*.*)'}, 'Select image for load',[cd '\']);
if ~isequal(image_file, 0)
    image_file = fullfile(image_path_name, image_file);
    image_rgb = double(imread(image_file)) / 255;
    handles.working_image = image_rgb;
    handles.path = image_file;
end
imshow(handles.working_image);
handles.image_loaded = true;

set(handles.info,'String','Image loaded. Press 3rd button to find answer.');

guidata(hObject, handles);

% --- Executes on button press in load_database.
function load_database_Callback(hObject, eventdata, handles)
% hObject    handle to load_database (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data_path = uigetdir();
'Database is loading'

painting_path = [data_path '/Painting'];
photograph_path = [data_path '/Photograph'];

[triplet, saturation, edges] = process_database(painting_path);
handles.painting_triplet = triplet;
handles.painting_saturation = saturation;
handles.painting_edges = edges;

[triplet, saturation, edges] = process_database(photograph_path);
handles.photograph_triplet = triplet;
handles.photograph_saturation = saturation;
handles.photograph_edges = edges;

set(handles.info,'String','Database loaded. Load image.');

guidata(hObject, handles);
    
function [median_triplet, median_saturation, median_edges] = process_database(path)
images = dir(fullfile(path, '*.jpg'));

unique_rgb_triplets = zeros(1,length(images));
saturation = zeros(1, length(images));
edges = zeros(1, length(images));

for idx = 1:length(images)
    image_path = fullfile(path, images(idx).name);
    image = double(imread(image_path)) / 255;
    
    [triplet, saturation, edges] = calculate_features(image);
    
    unique_rgb_triplets(idx) = triplet;
    
    saturation(idx) = saturation;
    
    edges(idx) = edges;
end

median_triplet = median(unique_rgb_triplets);
median_saturation = median(saturation);
median_edges = median(edges);

function [triplet, saturation, edges] = calculate_features(image)
R = image(:, :, 1);
G = image(:, :, 2);
B = image(:, :, 3);

triplet = 1000000 * R + 1000 * G + B;
triplet = length(unique(triplet));

hsv = rgb2hsv(image);
s = hsv(:, :, 2);
a = s(:) > 0.78;
saturation = sum(a);

image_edge = edge(rgb2gray(image), 'canny');
I = R * 0.3 + G * 0.6 + B * 0.1;
Rn = R / I;
Gn = G / I;
Bn = B / I;
R_edge = edge(Rn, 'canny');
G_edge = edge(Gn, 'canny');
B_edge = edge(Bn, 'canny');
sum_rgb = sum(R_edge | G_edge | B_edge);
edges = sum(sum(image_edge)) / sum(sum_rgb);


% --- Executes on button press in photo_or_painting.
function photo_or_painting_Callback(hObject, eventdata, handles)
% hObject    handle to photo_or_painting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[triplet, saturation, edges] = calculate_features(handles.working_image);

chance_of_painting = 0;
saturation_half = (handles.painting_saturation + handles.photograph_saturation) / 2;
triplet_half = (handles.painting_triplet + handles.photograph_triplet) / 2;
edges_half = (handles.painting_edges + handles.photograph_edges) / 2;

if saturation > saturation_half
    chance_of_painting = chance_of_painting + 1;
end
if triplet > triplet_half
    chance_of_painting = chance_of_painting + 1;
end
if edges < edges_half
    chance_of_painting = chance_of_painting + 1;
end

if chance_of_painting >= 2
    set(handles.info,'String','Image is Painting.');
else
    set(handles.info,'String','Image is Photo.');
end




    
