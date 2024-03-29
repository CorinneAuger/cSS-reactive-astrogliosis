%% End of layer analysis
% Use after edge_analysis.m to convert from object densities to object counts.

%% User input
stain = 'Iron';
make_cortex_figure = 0; % toggle on if want to run on loop for cortex figure checking

%% Input one directory needed so far
% Have to do it again below
directory.variables = sprintf('/Users/corinneauger/Documents/Aiforia heatmap coregistration/Saved data/Edge analysis/%s 1000um', stain);

%% Constant for the whole loop
one_iron_pixel_in_sq_microns = 6.603822^2;

%% Start loop for all sections
for brain = [1:3, 5, 7:9, 11, 13:15, 17:18, 20:25]
    for block = [1 4 5 7]
        
        %% Load edge variables
        cd(directory.variables)
        variables_file_name = sprintf('CAA%d_%d_%s_edge_analysis_variables.mat', brain, block, stain);
        
        if isfile(variables_file_name)
            load(variables_file_name);
            
            %% Input directories
            directory.variables = sprintf('/Users/corinneauger/Documents/Aiforia heatmap coregistration/Saved data/Edge analysis/%s 1000um', stain);
            directory.GFAP_heat_map = '/Volumes/Corinne hard drive/cSS project/Saved data/One-pixel density comparison/GFAP/Crucial variables';
            directory.CD68_heat_map = '/Volumes/Corinne hard drive/cSS project/Saved data/One-pixel density comparison/CD68/Crucial variables';
            directory.save_line_plot = sprintf('/Volumes/Corinne hard drive/cSS project/Saved data/Edge analysis/Individual slides/%s 1000um/Density line plot figures', stain);
            directory.save_cortex_figure = sprintf('/Volumes/Corinne hard drive/cSS project/Saved data/Edge analysis/Individual slides/%s 1000um/Cortex figures', stain);
            directory.save_variables = sprintf('/Volumes/Corinne hard drive/cSS project/Saved data/Edge analysis/Individual slides/%s 1000um/Variables', stain);
            directory.scripts = '/Volumes/Corinne hard drive/cSS project/Scripts/Layer analysis';
            
            %% Load heat map
            clear heat_map
            
            if strcmp('Iron', stain)
                
                % Try to load from CD68 data
                cd(directory.CD68_heat_map)
                heat_map_file_name_CD68 = sprintf('CAA%d_%d_CD68_and_Iron_1pixel_density_comparison_crucial_variables.mat', brain, block);
                if isfile(heat_map_file_name_CD68)
                    tmp = load(heat_map_file_name_CD68, 'iron_heat_map');
                    heat_map = tmp.iron_heat_map;
                    
                    %Try to load from GFAP data if CD68 didn't work
                else
                    cd(directory.GFAP_heat_map)
                    heat_map_file_name_GFAP = sprintf('CAA%d_%d_GFAP_and_Iron_1pixel_density_comparison_crucial_variables.mat', brain, block);
                    
                    if isfile(heat_map_file_name_GFAP)
                        tmp = load(heat_map_file_name_GFAP, 'iron_heat_map');
                        heat_map = tmp.iron_heat_map;
                    else
                        continue
                    end
                end
            else
                
                % Get directory
                if strcmp('GFAP', stain)
                    cd(directory.GFAP_heat_map)
                elseif strcmp('CD68', stain)
                    cd(directory.CD68_heat_map)
                end
                
                % Load heat map
                heat_map_file_name = sprintf('CAA%d_%d_%s_and_Iron_1pixel_density_comparison_crucial_variables.mat', brain, block, stain);
                
                if isfile(heat_map_file_name)
                    tmp = load(heat_map_file_name, 'inflammation_heat_map');
                    heat_map = tmp.inflammation_heat_map;
                else
                    continue
                end
            end
        else
            continue
        end
        
        %% Get ready to apply masks to heat map
        clear x y heat_map_layers layer_densities layer_too_small k l m
        [x, y] = size(heat_map);
        
        % Set maximum number of layers to 5
        if number_of_layers > 5
            number_of_layers = 5;
        end
        
        % Preallocate
        heat_map_layers = NaN(x,y,number_of_layers);
        uncorrected_heat_map_layers = NaN(x,y,number_of_layers);
        layer_densities = NaN(1, number_of_layers);
        
        %% Apply masks to heat map
        for k = 1:5
            
            % Replicate the heat map
            heat_map_layers(:,:,k) = heat_map;
            uncorrected_heat_map_layers(:,:,k) = heat_map;
            
            % Make everything not in the layer a NaN
            for l = 1:x
                for m = 1:y
                    if layer_masks(l,m,k) == 0 || cortex_mask(l,m) == 0
                        heat_map_layers(l,m,k) = NaN;
                    end
                   
                    if layer_masks(l,m,k) == 0 || opposite_tissue_mask(l,m) == 1
                        uncorrected_heat_map_layers(l,m,k) = NaN;
                    end
                    
                end
            end
            
            %% Calculate numerator for layer density
            objects_in_layer = nansum(nansum(heat_map_layers(:,:,k)));
            
            %% Calculate denominator for layer density
            pixels_in_uncorrected_layer = sum(sum(~isnan(uncorrected_heat_map_layers(:,:,k))));
            microns_in_layer = pixels_in_uncorrected_layer * one_iron_pixel_in_sq_microns;
            
            %% Calculate layer density
            layer_densities(k) = objects_in_layer/microns_in_layer;
            
            clear objects_in_layer pixels_in_layer microns_in_layer
        end
        
        %% Make and save line plot figure
        
        % Prepare color palettes
        color = jet(number_of_layers);
        dark_color = color./2;
        
        % Plot line
        figure;
        plot(layer_densities, 'Color', 'black', 'LineStyle', '-', 'LineWidth', 1.5);
        hold on
        
        % Plot points
        for k = 1:number_of_layers
            scatter(k, layer_densities(k), 100, 'filled', 'MarkerEdgeColor', dark_color((number_of_layers + 1)-k,:), 'MarkerFaceColor', color((number_of_layers + 1)-k,:));
            hold on
        end
        
        % X axis
        xlim([0, (number_of_layers + 1)]);
        set(gca,'xticklabel',[])
        set(gca,'XTick',[])
        
        % Y axis
        a = get(gca,'YTickLabel');
        set(gca, 'YTickLabel', a, 'fontsize', 11, 'fontweight', 'bold')
        
        % Axis labels
        xlabel('1000 �m layer', 'FontSize', 20, 'FontWeight', 'bold');
        
        if strcmp(stain, 'Iron')
            ylabel('Iron deposits per �m^2', 'FontSize', 20, 'FontWeight', 'bold');
        elseif strcmp(stain, 'GFAP')
            ylabel('GFAP-positive cells per �m^2', 'FontSize', 20, 'FontWeight', 'bold');
        elseif strcmp(stain, 'CD68')
            ylabel('CD68-positive cells per �m^2', 'FontSize', 20, 'FontWeight', 'bold');
        end
        
        % Title
        title('Example section', 'FontSize', 25)
        
        % Border
        box on
        ax = gca;
        ax.LineWidth = 1;
        
        % Save
        cd(directory.save_line_plot)
        line_plot_save_name = sprintf('CAA%d_%d_%s_layer_density_line_plot.png', brain, block, stain');
        saveas(gcf, line_plot_save_name)
        close all
        
        %% Make cortex figure
        
        if make_cortex_figure 
            % Set up for colors
            color = jet(number_of_layers);
            double_tissue_mask = double(tissue_mask);
            rainbow_figure = cat(3, double_tissue_mask, double_tissue_mask, double_tissue_mask);

            % Add colors
            for k = 1:number_of_layers
                for l = 1:x
                    for m = 1:y
                        if layer_masks(l,m,k) == 1
                            rainbow_figure(l,m,:) = color((number_of_layers + 1)-k,:);
                        end
                    end
                end
            end

            % Display figure
            figure;
            imshow(rainbow_figure)

            % Save
            cd(directory.save_cortex_figure)

            cortex_figure_save_name = sprintf('CAA%d_%d_%s_cortex_figure.png', brain, block, stain);
            saveas(gcf, cortex_figure_save_name);
        end
        
        
        %% Save variables
        cd(directory.save_variables)
        all_variables_save_name = sprintf('CAA%d_%d_%s_edge_analysis_variables.mat', brain, block, stain);
        save(all_variables_save_name);
    end
end

%% Make overall figure
cd(directory.scripts)
layer_analysis_composite(stain);
