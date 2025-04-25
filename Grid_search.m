clear; close all; clc;
% ----------------------
% SYNTHETIC DATA
% ----------------------
true_x = 30.5;
true_y = 30;
true_t0 = 10;

x_sta = [10, 40, 60, 20, 50];
y_sta = [10, 20, 10, 50, 40];

v = 6; % velocity (km/s)

dist_true = sqrt((x_sta - true_x).^2 + (y_sta - true_y).^2);
t_obs = true_t0 + dist_true / v;

% ----------------------
% PARAMETER GRID SEARCH
% ----------------------
x_range = 0:3:70;
y_range = 0:3:70;
t0_range = 8:0.1:12;

misfit_map = zeros(length(y_range), length(x_range));
misfit_min = inf;

% ----------------------
% PLOTTING
% ----------------------
figure('Units', 'pixels', 'Position', [100, 100, 1000, 500]);
[X_grid, Y_grid] = meshgrid(x_range, y_range);
% Subplot 1
subplot(1,2,1);
misfit_img = imagesc(x_range, y_range, misfit_map); hold on
scatter(X_grid(:), Y_grid(:), 10, [0.7 0.7 0.7], 'filled'); % titik grid abu-abu
axis xy; axis equal;
xlim([0 70]); ylim([0 70]);
hold on;
plot(true_x, true_y, 'kp', 'MarkerSize', 15, 'MarkerFaceColor', 'y');
misfit_point = plot(NaN, NaN, 'rx', 'MarkerSize', 12, 'LineWidth', 2);
xlabel('X (km)');
ylabel('Y (km)');
title('Misfit Map');

% Subplot 2
subplot(1,2,2);
hold on; grid on; axis equal;
xlim([0 70]); ylim([0 70]); hold on
scatter(X_grid(:), Y_grid(:), 10, [0.7 0.7 0.7], 'filled');
b1=scatter(x_sta, y_sta, 100, 'b', 'filled','DisplayName','Stations');
text(x_sta+1, y_sta+1, arrayfun(@(i) sprintf('Station %d', i), 1:length(x_sta), 'UniformOutput', false));
b2=plot(true_x, true_y, 'kp', 'MarkerSize', 15, 'MarkerFaceColor', 'y','DisplayName','True Epicenter');
best_pt = plot(NaN, NaN, 'rp', 'MarkerSize', 15, 'MarkerFaceColor', 'r','DisplayName','Predicted');
curr_grid_pt = plot(NaN, NaN, 'rx', 'MarkerSize', 12, 'LineWidth', 2,'DisplayName','Current Grid Point');

xlabel('X (km)'); ylabel('Y (km)');
title('Grid search for epicenter position');
legend([b1, b2, best_pt,curr_grid_pt],'Location','northwest');
axis xy;

% ----------------------
%  GIF
filename = 'GS_episenter.gif';
video_filename = 'grid_search_episenter.mp4';
vid = VideoWriter(video_filename, 'MPEG-4');
vid.FrameRate = 20;  % frame per second
open(vid);


drawnow;

% ----------------------
% GRID SEARCH Process
% ----------------------
for ix = 1:length(x_range)
    for iy = 1:length(y_range)
        x_src = x_range(ix);
        y_src = y_range(iy);

        for it0 = 1:length(t0_range)
            t0 = t0_range(it0);

            dist = sqrt((x_sta - x_src).^2 + (y_sta - y_src).^2);
            t_calc = t0 + dist / v;
            misfit = sqrt(mean((t_obs - t_calc).^2));

            if it0 == round(length(t0_range)/2)
                misfit_map(iy, ix) = misfit;
                set(misfit_img, 'CData', misfit_map);
                set(misfit_point, 'XData', x_src, 'YData', y_src);
            end

            if misfit < misfit_min
                misfit_min = misfit;
                best_x = x_src;
                best_y = y_src;
                best_t0 = t0;
                set(best_pt, 'XData', best_x, 'YData', best_y);
            end
        end

        set(curr_grid_pt, 'XData', x_src, 'YData', y_src);
        pause(0.01);

        % Capture frame
        frame = getframe(gcf);
        im = frame2im(frame);
        [A,map] = rgb2ind(im,256);

        % gif
        if ix == 1
            imwrite(A, map, filename, 'gif', 'LoopCount', Inf, 'DelayTime', 0.01);
        else
            imwrite(A, map, filename, 'gif', 'WriteMode', 'append', 'DelayTime', 0.01);
        end


        writeVideo(vid, frame);

    end


end
close(vid);


% ----------------------
% OUTPUT 
% ----------------------
fprintf('Episenter sebenarnya: (%.2f km, %.2f km), t0 = %.2f s\n', true_x, true_y, true_t0);
fprintf('Hasil Inversi:\n');
fprintf('Lokasi episenter: (%.2f km, %.2f km)\n', best_x, best_y);
fprintf('Origin time: %.2f s\n', best_t0);
fprintf('RMS Misfit: %.4f s\n', misfit_min);
