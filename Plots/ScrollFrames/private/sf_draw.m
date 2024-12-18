function p = sf_draw(hAx, p)

global sf_types_how
global sf_types_colormap

CURSOR_WAIT_gcfsave = gcbf;
set(gcbf,'Pointer','watch');
drawnow;

[p, zrCommon, zrLevel, sz3] = sf_prepare_field(p);

cla(hAx);

% scale = [1 1];
% scale = [1 1]/2;

pos = get(hAx, 'Position');
sz = size(p.B);
rel = pos([4 3])./sz;
rel = min(rel);
scale = [rel rel];

offset = [0 0];
zr = pick(logical(p.common_scale), zrCommon, zrLevel);
dh = zr(2) - zr(1);
switch p.colormap
    case sf_types_colormap.Asymm_Red_Blue
        cmap = colormapAsymm(zr);
    case sf_types_colormap.Parula
        cmap = parula;
end
if p.common_color
    cmap = l_scale_colormap(cmap, zrCommon, zrLevel);
end
if p.filter && isnan(p.filter_replace)
    cmap = [0.9 0.9 0.9; cmap];
end
switch p.how
    case sf_types_how.Surface
        hIm = surfc(hAx, p.B, 'EdgeColor', 'none');
%         [a, b] = lastwarn;
%         disp(b)
        if (dh > 0)
            set(hAx, 'ZLim', zr);
            M = sqrt(sz3(1)*sz3(2));
            asp = dh/M;
        else
            asp = 1;
        end
        set(hAx, 'DataAspectRatio', [1,1,asp]);
        colormap(hAx, cmap);
        hold on
    case sf_types_how.Image
        B = (p.B-zr(1))/dh*(size(cmap, 1)-1) + 1;
        hIm = image(hAx, (0:size(B, 2)-1)*scale(2) + offset(2), (0:size(B, 1)-1)*scale(1) + offset(1), ...
              B, 'CDataMapping','direct', 'AlphaDataMapping','none', 'AlphaData',1);
        set(hAx, 'YDir','normal', 'Layer', 'top');
        set(hAx, 'DataAspectRatio', [1,1,1]);
        colormap(hAx, cmap);
        
        c = colorbar;
        ticks = l_getTicks(zr, 10);
        ticksVal = (ticks-zr(1))/dh*(size(cmap, 1)-1) + 1;
        set(c, 'TickLabelsMode', 'manual', 'TicksMode', 'manual', 'Ticks', ticksVal, 'TickLabels', num2cell(ticks));
        set(hAx, 'ZLim', [0 1]);
        hold on
        
        if ~isempty(p.Bq1) && ~isempty(p.Bq1)
            
            plainStep = 2;
            lineLength = 0.8;
            color = 'g';
            lineWidth = 1;
            
            Bxex = zeros(size(p.Bq1));
            Bxex(1:plainStep:size(p.Bq1, 1), 1:plainStep:size(p.Bq1, 2)) = p.Bq1(1:plainStep:size(p.Bq1, 1), 1:plainStep:size(p.Bq1, 2));
            Byex = zeros(size(p.Bq2));
            Byex(1:plainStep:size(p.Bq2, 1), 1:plainStep:size(p.Bq2, 2)) = p.Bq2(1:plainStep:size(p.Bq2, 1), 1:plainStep:size(p.Bq2, 2));
            hIm = quiver(hAx, (0:size(p.Bq1, 2)-1)*scale(2)+offset(2), (0:size(p.Bq1, 1)-1)*scale(1)+offset(1), Byex, Bxex, ...
                         'AutoScale', 'on', 'AutoScaleFactor', lineLength*plainStep, 'Color', color, 'LineWidth', lineWidth);
        end
        
    case sf_types_how.Contour
        [layers, step] = l_getTicks(zr, p.levels);
        [~, hIm] = contour(hAx, (0:size(p.B, 2)-1)*scale(2)+offset(2), (0:size(p.B, 1)-1)*scale(1)+offset(1), p.B, ...
                          'LevelList', layers, 'TextList', min(layers):(step*p.label_each):max(layers), 'Fill', 'off', 'ShowText', 'on');
        set(hAx, 'ZLim', [0 1]);
        colormap(hAx, cmap);
        hold on
end

set(hIm, 'ButtonDownFcn', @(hObject,eventdata)ScrollFrame('axes1_ButtonDownFcn',hObject,eventdata,guidata(hObject)));

if ~p.trim_draw && p.allow_trim
    if ~isempty(p.trimdata.LT)
        LT = p.trimdata.LT - p.bound_shift(1:2) - 1 + [-0.5, 0.5];
        if isempty(p.trimdata.RB)
            szline = size(p.B, 2)*scale(2)/24;
            plot([LT(1)-szline LT(1)+szline], [LT(2) LT(2)], 'Color', 'k', 'LineWIdth', 2);
            plot([LT(1) LT(1)], [LT(2)-szline LT(2)+szline], 'Color', 'k', 'LineWIdth', 2);
        else
            RB = p.trimdata.RB - p.bound_shift(1:2) - 1 + [0.5, -0.5];
            plot([LT(1) LT(1)], [RB(2) LT(2)], 'Color', 'k', 'LineWIdth', 2);
            plot([RB(1) RB(1)], [RB(2) LT(2)], 'Color', 'k', 'LineWIdth', 2);
            plot([LT(1) RB(1)], [LT(2) LT(2)], 'Color', 'k', 'LineWIdth', 2);
            plot([LT(1) RB(1)], [RB(2) RB(2)], 'Color', 'k', 'LineWIdth', 2);
        end
    end
end

if ~isempty(p.select)
    show_sel = true;
    xy0 = p.select.xy - 1;
    if p.trim_draw && ~isempty(p.trim)
        xrange = p.trim.xrange;
        yrange = p.trim.yrange;
        if xy0(1) >= xrange(1) - 1 && xy0(1) < xrange(2) && xy0(2) >= yrange(1) - 1 && xy0(2) < yrange(2)
            xy0 = xy0 - p.trim.offset;
            disp(['xy0 ' num2str(xy0(1)) ', ' num2str(xy0(2))])
            disp(['off ' num2str(p.trim.offset(1)) ', ' num2str(p.trim.offset(2))])
        else
            show_sel = false;
        end
    else
        xy0 = xy0 - p.bound_shift(1:2);
    end
    if ~p.trim_draw || show_sel
        plot(xy0(2), xy0(1), 'LineStyle', 'none', 'Marker', 'o', 'MarkerSize', 7, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'k');
    end
end

% if common_color
%     caxis(hAx, Zrange);
% end

set(CURSOR_WAIT_gcfsave,'Pointer','arrow'); % 'arrow'

end

%------------------------------------------------------------------------
function [ticks, step] = l_getTicks(zr, n)

dh = zr(2)-zr(1);
step = dh/n;
p = log10(step);
m = p-floor(p);
nm = pick(m < log10(1.5), 0, pick(m < log10(3.5), log10(2), pick(m < log10(7.5), log10(5), 1)));
step = 10^(floor(p)+nm);
ticks = 0:step:max(abs(zr));
ticks = [-flip(ticks) ticks(2:end)];
ticks(ticks < zr(1) | ticks > zr(2)) = [];

end

%------------------------------------------------------------------------
function csc = l_scale_colormap(cmap, Zr, zr)

csc = zeros(size(cmap));
N = size(cmap, 1);

n(1) = (zr(1) - Zr(1))/(Zr(2) - Zr(1))*(N-1) + 1;
n(2) = (zr(2) - Zr(1))/(Zr(2) - Zr(1))*(N-1) + 1;
ns = linspace(n(1), n(2), N);

csc(:, 1) = l_make_cm_d(1:N, cmap(:, 1)', ns);
csc(:, 2) = l_make_cm_d(1:N, cmap(:, 2)', ns);
csc(:, 3) = l_make_cm_d(1:N, cmap(:, 3)', ns);

end

%------------------------------------------------------------------------
function v = l_make_cm_d(X, Y, x)

v = interp1(X, Y, x);
v = v';

end
