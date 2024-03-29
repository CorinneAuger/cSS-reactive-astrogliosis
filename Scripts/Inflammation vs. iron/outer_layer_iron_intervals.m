function [edge_only_means, no_edge_means] = outer_layer_iron_intervals(brain, inflammatory_marker)
% Makes final matrices and graphs of iron vs. inflammation data, first only looking at the outermost 1000um (basically the outermost layer of pixels), then only looking at the cortex without the outermost 1000um.
% For the outer layer, pixels are 250um * 250um instead of the usual 500um * 500um.

close all

%% Input directories
directory.input = sprintf('/Volumes/Corinne hard drive/cSS project/Saved data/One-pixel density comparison/%s/Crucial variables', inflammatory_marker);
directory.heat_map_scripts = '/Volumes/Corinne hard drive/cSS project/Scripts/Heat map analysis';
directory.IvsI_scripts = '/Volumes/Corinne hard drive/cSS project/Scripts/Inflammation vs. iron';
directory.edge_mask = '/Volumes/Corinne hard drive/cSS project/Saved data/Edge analysis/Individual slides/Iron 1000um/Variables';
directory.save_heat_map_figures = sprintf('/Volumes/Corinne hard drive/cSS project/Saved data/One-pixel outer and inner layer interval analysis/%s/Heat map figures', inflammatory_marker);
directory.save_interval_figures = sprintf('/Volumes/Corinne hard drive/cSS project/Saved data/One-pixel outer and inner layer interval analysis/%s/Interval figures', inflammatory_marker);
directory.save_means = sprintf('/Volumes/Corinne hard drive/cSS project/Saved data/One-pixel outer and inner layer interval analysis/%s/Means', inflammatory_marker);

for block = [1, 4, 5, 7]
    %% Import coregistered scatter plots
    variables_file = sprintf('CAA%d_%d_%s_and_Iron_1pixel_density_comparison_crucial_variables.mat', brain, block, inflammatory_marker);
    cd(directory.input)
    
    if isfile(variables_file)    % exclude sections that couldn't coregister
        load(variables_file, 'iron_heat_map');
        load(variables_file, 'inflammation_heat_map');
        
        %% Import edge mask
        cd(directory.edge_mask)
        edge_mask_file_name = sprintf('CAA%d_%d_Iron_edge_analysis_variables.mat', brain, block);
        
        if isfile(edge_mask_file_name)
            load(edge_mask_file_name, 'layer_masks')
            
            %% Apply edge mask
            [size_x, size_y, ~] = size(layer_masks);
            
            % Preallocate
            edge_only_iron_scatter = iron_heat_map;
            edge_only_inflammation_scatter = inflammation_heat_map;
            
            no_edge_iron_scatter = iron_heat_map;
            no_edge_inflammation_scatter = inflammation_heat_map;
            
            for l = 1 : size_x
                for m = 1 : size_y
                    if layer_masks(l,m,1) == 0
                        edge_only_iron_scatter(l,m,1) = NaN;
                        edge_only_inflammation_scatter(l,m,1) = NaN;
                    elseif layer_masks(l,m,1) == 1
                        no_edge_iron_scatter(l,m,1) = NaN;
                        no_edge_inflammation_scatter(l,m,1) = NaN;
                    end
                end
            end
            
            %% Set up density calculations
            clear stat_iron stat_inflammation
            matlab_pixel_size = 6.603822; %microns
            
            %% Calculate densities for edge only
            iron_heat_map = edge_only_iron_scatter;
            inflammation_heat_map = edge_only_inflammation_scatter;
            
            patch_size_microns = 250;
            patch_size_pixels = round(patch_size_microns / matlab_pixel_size); % = 76
            size_patch = [patch_size_pixels, patch_size_pixels];
            
            cd(directory.heat_map_scripts)
            edge_only_stat_iron = PatchGenerator_density_comparison(iron_heat_map, size_patch, size_patch, 'Values');
            edge_only_stat_inflammation = PatchGenerator_density_comparison(inflammation_heat_map, size_patch, size_patch, 'Values');
            
            %% Caculate densities for no edge
            clear iron_heat_map inflammation_heat_map
            iron_heat_map = no_edge_iron_scatter;
            inflammation_heat_map = no_edge_inflammation_scatter;
            
            patch_size_microns = 500;
            patch_size_pixels = round(patch_size_microns / matlab_pixel_size); % = 76
            size_patch = [patch_size_pixels, patch_size_pixels];
            
            cd(directory.heat_map_scripts)
            no_edge_stat_iron = PatchGenerator_density_comparison(iron_heat_map, size_patch, size_patch, 'Values');
            no_edge_stat_inflammation = PatchGenerator_density_comparison(inflammation_heat_map, size_patch, size_patch, 'Values');
            
            %% Make figure
            figure;
            
            % Edge only iron
            subplot(2, 2, 1)
            imshow(edge_only_stat_iron(:,:), [0 ((patch_size_pixels^2) * 0.005)]);
            title(sprintf('Outer 1000um only: CAA%d__%d_Iron', brain, block));
            axis image;
            axis off;
            colormap(gca, jet);
            colorbar;
            
            % No edge iron
            subplot(2, 2, 2)
            imshow(no_edge_stat_iron(:,:), [0 ((patch_size_pixels^2) * 0.005)]);
            title(sprintf('Without outer 1000um: CAA%d__%d_Iron', brain, block));
            axis image;
            axis off;
            colormap(gca, jet);
            colorbar;
            
            % Edge only inflammation
            subplot(2, 2, 3)
            if strcmp(inflammatory_marker, 'CD68') == 1
                imshow(edge_only_stat_inflammation,[0 (patch_size_pixels^2) * 0.005]);
            elseif strcmp(inflammatory_marker, 'GFAP') == 1
                imshow(edge_only_stat_inflammation,[0 (patch_size_pixels^2) * 0.005])
            end
            
            title(sprintf('Outer 1000um only: CAA%d__%d_%s', brain, block, inflammatory_marker));
            axis image;
            axis off;
            colormap(gca, jet);
            colorbar;
            
            % No edge inflammation
            subplot(2, 2, 4)
            if strcmp(inflammatory_marker, 'CD68') == 1
                imshow(no_edge_stat_inflammation,[0 (patch_size_pixels^2) * 0.005]);
            elseif strcmp(inflammatory_marker, 'GFAP') == 1
                imshow(no_edge_stat_inflammation,[0 (patch_size_pixels^2) * 0.005])
            end
            
            title(sprintf('Without outer 1000um: CAA%d__%d_%s', brain, block, inflammatory_marker));
            axis image;
            axis off;
            colormap(gca, jet);
            colorbar;
            
            %% Save heat map figure
            cd(directory.save_heat_map_figures)
            figure_save_name = sprintf('CAA%d_%d_%s_and_Iron_outer_layer_heat_map_figure.png', brain, block, inflammatory_marker);
            saveas(gcf, figure_save_name);
            
            %% Classify each pixel into very low, low, medium, or high iron density
            % In interval_plot_iron, very low = 0, low = 1, medium = 2, high = 3
            % When q = 1, edge only. When q = 2, no edge.
            cd(directory.IvsI_scripts)
            [no_edge_block_vector_iron, no_edge_block_vector_inflammation] = pixel_classifier(no_edge_stat_iron, no_edge_stat_inflammation, 500);
            [edge_only_block_vector_iron, edge_only_block_vector_inflammation] = pixel_classifier(edge_only_stat_iron, edge_only_stat_inflammation, 250);
            
            %% Make vectors of the interval categorizations for all the blocks in the brain
            if block == 1
                no_edge_vector_interval_iron = no_edge_block_vector_iron;
                no_edge_vector_interval_inflammation = no_edge_block_vector_inflammation;
                
                edge_only_vector_interval_iron = edge_only_block_vector_iron;
                edge_only_vector_interval_inflammation = edge_only_block_vector_inflammation;
            else
                no_edge_vector_interval_iron = [no_edge_vector_interval_iron, no_edge_block_vector_iron];
                no_edge_vector_interval_inflammation = [no_edge_vector_interval_inflammation, no_edge_block_vector_inflammation];
                
                edge_only_vector_interval_iron = [edge_only_vector_interval_iron, edge_only_block_vector_iron];
                edge_only_vector_interval_inflammation = [edge_only_vector_interval_inflammation, edge_only_block_vector_inflammation];
                
            end
            
            %% Deal with excluded sections
        else
            vector_interval_iron = NaN;
            vector_interval_inflammation = NaN;
            
            if block == 1
                edge_only_vector_interval_iron = NaN;
                edge_only_vector_interval_inflammation = NaN;
                no_edge_vector_interval_iron = NaN;
                no_edge_vector_interval_inflammation = NaN;
            else
                edge_only_vector_interval_iron = [edge_only_vector_interval_iron, NaN];
                edge_only_vector_interval_inflammation = [edge_only_vector_interval_inflammation, NaN];
                no_edge_vector_interval_iron = [no_edge_vector_interval_iron, NaN];
                no_edge_vector_interval_inflammation = [no_edge_vector_interval_inflammation, NaN];
            end
        end
    else
        vector_interval_iron = NaN;
        vector_interval_inflammation = NaN;
        
        if block == 1
            edge_only_vector_interval_iron = NaN;
            edge_only_vector_interval_inflammation = NaN;
            no_edge_vector_interval_iron = NaN;
            no_edge_vector_interval_inflammation = NaN;
        else
            edge_only_vector_interval_iron = [edge_only_vector_interval_iron, NaN];
            edge_only_vector_interval_inflammation = [edge_only_vector_interval_inflammation, NaN];
            no_edge_vector_interval_iron = [no_edge_vector_interval_iron, NaN];
            no_edge_vector_interval_inflammation = [no_edge_vector_interval_inflammation, NaN];
        end
    end
end

%% Get mean for each interval grouping
close all
clear i j q

for q = 1:2
    if q == 1
        vector_interval_iron = edge_only_vector_interval_iron;
        vector_interval_inflammation = edge_only_vector_interval_inflammation;
    elseif q == 2
        vector_interval_iron = no_edge_vector_interval_iron;
        vector_interval_inflammation = no_edge_vector_interval_inflammation;
    end
    
    for i = 3:-1:0
        indices = find(vector_interval_iron == i);
        [~, indices_length] = size(indices);
        
        values = NaN(1, indices_length);
        
        for j = 1: indices_length
            values(j) = vector_interval_inflammation(indices(j));
        end
        
        if i == 0
            very_low_mean = nanmean(values);
        elseif i == 1
            low_mean = nanmean(values);
        elseif i == 2
            medium_mean = nanmean(values);
        elseif i == 3
            high_mean = nanmean(values);
        end
    end
    
    means = [very_low_mean; low_mean; medium_mean; high_mean];
    
    if q == 1
        edge_only_means = means;
    elseif q == 2
        no_edge_means = means;
    end
    
    %% Make figure
    figure;
    
    scatter(vector_interval_iron, vector_interval_inflammation, 'black', '.');
    hold on
    scatter([0; 1; 2; 3], means, 100, 'red', 'x');
    
    xlabel('Iron objects in patch', 'FontSize', 16);
    xticks([0 1 2 3]);
    xticklabels({'Very low', 'Low', 'Medium', 'High'});
    xlim([-0.5 3.5]);
    
    ylabel_name = sprintf('%s objects in patch', inflammatory_marker);
    ylabel(ylabel_name, 'FontSize', 16);
    ylim([0 (nanmax(nanmax(vector_interval_inflammation)))]);
    
    %% Save interval plot and matrix
    if q == 1
        title(sprintf('CAA%d, outer 1000um', brain), 'FontSize', 16);
        
        figure_save_name = sprintf('CAA%d__%s_1pixel_outer_1000um_interval_figure.png', brain, inflammatory_marker);
        cd(directory.save_interval_figures)
        saveas(gcf, figure_save_name);
        
        means_save_name = sprintf('CAA%d__%s_1pixel_outer_1000um_interval_means.mat', brain, inflammatory_marker);
        cd(directory.save_means)
        save(means_save_name, 'edge_only_means')
        
        clear figure_save_name means_save_name
    elseif q == 2
        title(sprintf('CAA%d, without outer 1000um', brain), 'FontSize', 16);
        
        figure_save_name = sprintf('CAA%d__%s_1pixel_no_edge_interval_figure.png', brain, inflammatory_marker);
        cd(directory.save_interval_figures)
        saveas(gcf, figure_save_name);
        
        means_save_name = sprintf('CAA%d__%s_1pixel_no_edge_interval_means.mat', brain, inflammatory_marker);
        cd(directory.save_means)
        save(means_save_name, 'no_edge_means')
    end
    
    clear vector_interval_iron vector_interval_inflammation indices indices_length values very_low_mean low_mean medium_mean high_mean means
    close all
end
