function plot_data = svg_to_qdex(filename, deviation_angle_rad)
    
    try
        root = xmlread(filename);
    catch
        error('File not found or invalid.');
        return;
    end
    
    plot_data = [];
    
    
    % find the drawing height and width
    drawing_height = 0;
    drawing_width = 0;
    
    length_root = length(root.Attributes);
    
    for (i = 1:length_root)
        if (strcmp(root.Attributes{i}.Name, 'height'))
            %drawing_height = str2num(root.Attributes{i}.Value);
            drawing_height = str2num(regexp(root.Attributes{i}.Value, '[0-9]+', 'match'){1});

        end
        if (strcmp(root.Attributes{i}.Name, 'width'))
%            drawing_width = str2num(root.Attributes{i}.Value);
            drawing_width = str2num(regexp(root.Attributes{i}.Value, '[0-9]+', 'match'){1});
        end
        
    end


    % count drawing elements
    [plot_data count] = find_and_process_children(root.Children, deviation_angle_rad, 1, 0);
	fprintf('\n%d elements to process...\n', count);
    
    % process SVG for drawing elements
    [plot_data count] = find_and_process_children(root.Children, deviation_angle_rad, 0, 0);

    fprintf('Done processing...\n');
	
    % vertically mirror to account for reversed coordinate system
    for i = 1:size(plot_data,2)
        plot_data(i).data(:,2) = ones(size(plot_data(i).data, 1),1).*drawing_height - plot_data(i).data(:,2);       
    end 
   

    fprintf(1, 'Done!\n\n');
    
end


function [plot_data count] = find_and_process_children(node, curve_threshold, count_only, current_count)

	count = 0;

	plot_data = [];
    
    % first process all graphical elements
    for i = 1:length(node)
        if (strcmp(node{i}.Name, 'path'))
			count = count + 1;
            
		    if (~count_only)

			    fprintf('Path (element %d)...\n', current_count + count);
		
          	    new_data = process_path(node{i}, curve_threshold);

        	    if ~isempty(new_data) 
    	            plot_data = [plot_data new_data];
	            end
			end
        elseif (strcmp(node{i}.Name, 'rect'))
			count = count + 1;
            
		    if (~count_only)

			    fprintf('Rectangle (element %d)...\n', current_count + count);
		
                new_data = process_rect(node{i});

        	    if ~isempty(new_data) 
    	            plot_data = [plot_data new_data];
	            end
			end
       elseif (strcmp(node{i}.Name, 'circle'))
			count = count + 1;
            
		    if (~count_only)

			    fprintf('Circle (element %d)...\n', current_count + count);
		
                new_data = process_circle(node{i});

        	    if ~isempty(new_data) 
    	            plot_data = [plot_data new_data];
	            end
			end

       elseif (strcmp(node{i}.Name, 'ellipse'))
			count = count + 1;
            
		    if (~count_only)

			    fprintf('Ellipse (element %d)...\n', current_count + count);
		
                new_data = process_ellipse(node{i});

        	    if ~isempty(new_data) 
    	            plot_data = [plot_data new_data];
	            end
			end
        end 
      
    end
    
    
    % now recursively process all groups
    length_node = length(node);
    
    for (i = 1:length_node)
        if (strcmp(node{i}.Name, 'g'))
            


			transform = [1 0 0
        		         0 1 0
                		 0 0 1];
                   
            process_group = 1;

		    for (j = 1:length(node{i}.Attributes))
		        if (strcmp(node{i}.Attributes{j}.Name, 'style'))       
                    % only process if it is not hidden
              
              if (strfind(node{i}.Attributes{j}.Value, 'display:none'))  
                       process_group = 0;
                    end
                
                elseif (strcmp(node{i}.Attributes{j}.Name, 'transform'))       
           		   % found transform so change default
        			
                   string = strtrim(node{i}.Attributes{j}.Value); %remove leading and trailing space
                   string = strrep(string, ',', ' '); %replace commas with space
        
        	       transform = process_transform(string, transform);                
            	end

		    end
      
      
            if (process_group)
                [plot_data_new new_count] = find_and_process_children(node{i}.Children, curve_threshold, count_only, current_count + count);
			    count = count + new_count;      

    	        for (j = 1:length(plot_data_new))
	 
	    	        plot_data_new(j).data = ((transform)*( plot_data_new(j).data') )';


	            end

    			plot_data = [plot_data plot_data_new];
             end



        end

		
        
    end    
end    
    

function element = process_path(node, curve_threshold)
    
    
    element = [];

	transform = [1 0 0
                 0 1 0
                 0 0 1];
    
    for (i = 1:length(node.Attributes))
        
       if (strcmp(node.Attributes{i}.Name, 'transform'))       
   		   % found transform so change default
			
           string = strtrim(node.Attributes{i}.Value); %remove leading and trailing space
           string = strrep(string, ',', ' '); %replace commas with space

	       transform = process_transform(string, transform);

           


       elseif (strcmp(node.Attributes{i}.Name, 'd'))
           %found path data, now format string into tokens
           
           string = strtrim(node.Attributes{i}.Value); %remove leading and trailing space
           string = strrep(string, ',', ' '); %replace commas with space
           

           % remove repeating white spaces
           if (length(string) > 0) 
               index = 2;
           
               while (index < length(string))
                   if ((string(index) == ' ') && (string(index-1) == ' '))
                       if (index == length(string))
                           % this case should not be necessary due to trim above, but just in case...
                           string = string(1:index-1);
                       else
                           string = [string(1:index-1) string(index+1:length(string))];
                       end
                   else
                       index = index + 1;
                   end                   
               end
                   
           else
               % nothing left
               element = [];
               return;   
           end    
           
           
           % add missing spaces
           if (length(string) > 0) 
               index = 2;
           
               while (index < length(string))
                   if ( (isalpha(string(index-1)) && (string(index) ~= ' ') && (string(index) ~= '-') && (string(index) ~= 'e')) || (isdigit(string(index-1)) && (isalpha(string(index)) && (string(index) ~= 'e'))) )
                       string = [string(1:index-1) ' ' string(index:length(string))];
                   else
                       index = index + 1;
                   end                   
               end
                   
           else
               % nothing left
               element = [];
               return;   
           end    
        
           
           
           if (length(string) > 0) 
               
               % Find tokens using space separator and add an extra index at the 
               % end to handle the final token the same way as mid-placed tokens.
               token_index = [strfind(string, ' ') (length(string)+1)];
               last_token_index = 1;
               
               draw_state = 'u'; %unknown
               element.data = [];
               
               index = 1;
               while (index <= length(token_index))
                   
%                    if (index <= length(token_index))
                       token = string(last_token_index:token_index(index)-1);
                       last_token_index = token_index(index)+1;
%                    else
%                        token = string(last_token_index:length(string));
%                    end
                   
                   index = index + 1;
                   
                   if (min(isalpha(token)) == 1)
                       if (strcmp(token, 'm') || strcmp(token, 'M'))
                           draw_state = token;
                           
                           %regardless of whether it is relative or absolute, the first two elements will be absolute.
                           token_x = string(last_token_index:token_index(index)-1);
                           token_y = string(token_index(index)+1:token_index(index+1)-1);
                           
                           last_token_index = token_index(index+1)+1;
                           index = index + 2;


                           %check if values are numeric
                           if ~isNumber(token_x)
                               id_string = 'unknown id';
                               
                               for id_search_count = 1:length(node.Attributes)
                                   if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                       id_string = node.Attributes{id_search_count}.Value;
                                   end
                               end
                               
                                fprintf('ERROR: Non-numeric value found at M/m command x location (%s).  ID %s.\n', token_x, id_string);   
                                element = [];
                                return;
                           elseif ~isNumber(token_y)
                               id_string = 'unknown id';
                               
                               for id_search_count = 1:length(node.Attributes)
                                   if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                       id_string = node.Attributes{id_search_count}.Value;
                                   end
                               end                               
                               
                                fprintf('ERROR: Non-numeric value found at M/m command y location (%s).  ID %s.\n', token_y, id_string);   
                                element = [];
                                return;
                           end
                                                     
                            % store data
                           element.data = [element.data; str2num(token_x) str2num(token_y)];
                           
                           % subsequent values will be treated as lines
                           if (draw_state == 'm')
                               draw_state = 'l';
                           end
                           
                           if (draw_state == 'M')
                               draw_state = 'L';
                           end
                           
                       elseif (strcmp(token, 'L') || strcmp(token, 'l'))
                           draw_state = token;                           

                           % Handle with default routine
                           
                           
                       elseif (strcmp(token, 'z') || strcmp(token, 'Z'))
                           % close the surface by repeating the first element.
                           
                           element.data = [element.data; element.data(1,:)];
                           
                       elseif (strcmp(token, 'c') || strcmp(token, 'C'))
                            draw_state = token;                           

                           % Handle with default routine         

                       elseif (strcmp(token, 'a') || strcmp(token, 'A'))
                            draw_state = token;                           

                           % Handle with default routine                     
                           
                       else
                           id_string = 'unknown id';
                           
                           for id_search_count = 1:length(node.Attributes)
                               if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                   id_string = node.Attributes{id_search_count}.Value;
                               end
                           end                             
                           
                           fprintf('\nWarning: Do not know how to handle path command type %s in <%s>.  ID %s.\n', token, string, id_string);
                           
                           % keep what has been done so far for the elements as long as there is at least one line segment
                           if ((size(element.data, 1) <= 1) || (size(element.data, 2) <= 1))
                               element = []
                           end
                           return
                       end
                       
                   else
                      % it's numeric
                      
                       if (draw_state == 'u')
                           id_string = 'unknown id';
                               
                           for id_search_count = 1:length(node.Attributes)
                               if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                   id_string = node.Attributes{id_search_count}.Value;
                               end
                           end 
                           
                           
                           fprintf('ERROR: Found numeric value when expecting command. ID %s.\n', id_string)
                           element = [];
                           return;
                       elseif ((draw_state == 'L') || (draw_state == 'l'))
                           
                           %there should be two tokens available
                           token_x = token;
                           token_y = string(last_token_index:token_index(index)-1);
                           
                           last_token_index = token_index(index)+1;
                           index = index + 1;
                           
                           %check if values are numeric
                           if ~isNumber(token_x)
                               id_string = 'unknown id';
                               
                               for id_search_count = 1:length(node.Attributes)
                                   if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                       id_string = node.Attributes{id_search_count}.Value;
                                   end
                               end 
                               
                                fprintf('ERROR: Non-numeric value found at L command x location (%s).  ID %s.\n', token_x, id_string);   
                                element = [];
                                return;
                           elseif ~isNumber(token_y)
                               id_string = 'unknown id';
                               
                               for id_search_count = 1:length(node.Attributes)
                                   if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                       id_string = node.Attributes{id_search_count}.Value;
                                   end
                               end 
                               
                                fprintf('ERROR: Non-numeric value found at L command y location (%s) <%s>.  ID %s.\n', token_y, string, id_string);   
                                element = [];
                                return;
                           end      
      
                            % store data
                           if (draw_state == 'L')
                               element.data = [element.data; str2num(token_x) str2num(token_y)];                           
                           else
                               element.data = [element.data; (str2num(token_x)+element.data(size(element.data,1),1)) (str2num(token_y)+element.data(size(element.data,1),2))];
                           end
                           
                       
                       elseif ((draw_state == 'C') || (draw_state == 'c'))
                           
                           %there should be six tokens available
                           token_x1 = token;
                           token_y1 = string(last_token_index:token_index(index)-1);
                           token_x2 = string(token_index(index)+1:token_index(index+1)-1);
                           token_y2 = string(token_index(index+1)+1:token_index(index+2)-1);                           
                           token_x = string(token_index(index+2)+1:token_index(index+3)-1);
                           token_y = string(token_index(index+3)+1:token_index(index+4)-1);                           
                           
                           last_token_index = token_index(index+4)+1;
                           index = index + 5;
                           
                           %check if values are numeric
                           if ~isNumber(token_x)
                                id_string = 'unknown id';
                               
                                for id_search_count = 1:length(node.Attributes)
                                    if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                        id_string = node.Attributes{id_search_count}.Value;
                                    end
                                end 
                               
                                fprintf('ERROR: Non-numeric value found at C command x location (%s).  ID %s.\n', token_x, id_string);   
                                element = [];
                                return;
                           elseif ~isNumber(token_y)
                                id_string = 'unknown id';
                               
                                for id_search_count = 1:length(node.Attributes)
                                    if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                        id_string = node.Attributes{id_search_count}.Value;
                                    end
                                end 
                               
                                fprintf('ERROR: Non-numeric value found at C command y location (%s).  ID %s.\n', token_y, id_string);   
                                element = [];
                                return;
                           elseif ~isNumber(token_x1)
                                id_string = 'unknown id';
                               
                                for id_search_count = 1:length(node.Attributes)
                                    if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                        id_string = node.Attributes{id_search_count}.Value;
                                    end
                                end 
                               
                                fprintf('ERROR: Non-numeric value found at C command x1 location (%s).  ID %s.\n', token_y, id_string);   
                                element = [];
                                return;
                           elseif ~isNumber(token_y1)
                                id_string = 'unknown id';
                               
                                for id_search_count = 1:length(node.Attributes)
                                    if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                        id_string = node.Attributes{id_search_count}.Value;
                                    end
                                end 
                               
                                fprintf('ERROR: Non-numeric value found at C command y1 location (%s).  ID %s.\n', token_y, id_string);   
                                element = [];
                                return;
                           elseif ~isNumber(token_x2)
                                id_string = 'unknown id';
                               
                                for id_search_count = 1:length(node.Attributes)
                                    if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                        id_string = node.Attributes{id_search_count}.Value;
                                    end
                                end 
                               
                                fprintf('ERROR: Non-numeric value found at C command x2 location (%s).  ID %s.\n', token_y, id_string);   
                                element = [];
                                return;
                           elseif ~isNumber(token_y2)
                                id_string = 'unknown id';
                               
                                for id_search_count = 1:length(node.Attributes)
                                    if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                        id_string = node.Attributes{id_search_count}.Value;
                                    end
                                end 
                               
                                fprintf('ERROR: Non-numeric value found at C command y2 location (%s).  ID %s.\n', token_y, id_string);   
                                element = [];
                                return;
                           end      
                           
                           
                           
                           token_x0 = element.data(size(element.data,1),1);
                           token_y0 = element.data(size(element.data,1),2);
                           token_x1 = str2num(token_x1);
                           token_y1 = str2num(token_y1);
                           token_x2 = str2num(token_x2);
                           token_y2 = str2num(token_y2);
                           token_x = str2num(token_x);
                           token_y = str2num(token_y);
                           
                           % convert to absolute
                           if (draw_state == 'c')
                               token_x1 = token_x1 + token_x0;
                               token_y1 = token_y1 + token_y0;
                               token_x2 = token_x2 + token_x0;
                               token_y2 = token_y2 + token_y0;
                               token_x = token_x + token_x0;
                               token_y = token_y + token_y0;                                
                           end

                           
                          element.data = [element.data; CalculateBezierCurveSeries(token_x0, token_x1, token_x2, token_x, token_y0, token_y1, token_y2, token_y, curve_threshold)];
                           
                           
                       elseif ((draw_state == 'A') || (draw_state == 'a'))
                           
                           %there should be seven tokens available
                           token_a = token;
                           token_b = string(last_token_index:token_index(index)-1);
                           token_alpha = string(token_index(index)+1:token_index(index+1)-1);
                           token_large_flag = string(token_index(index+1)+1:token_index(index+2)-1);                           
                           token_sweep_flag = string(token_index(index+2)+1:token_index(index+3)-1);
                           token_x1 = string(token_index(index+3)+1:token_index(index+4)-1);                           
                           token_y1 = string(token_index(index+4)+1:token_index(index+5)-1);                           
                           
                           last_token_index = token_index(index+5)+1;
                           index = index + 6;
                           
                           %check if values are numeric
                           if ~isNumber(token_a)
                                id_string = 'unknown id';
                               
                                for id_search_count = 1:length(node.Attributes)
                                    if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                        id_string = node.Attributes{id_search_count}.Value;
                                    end
                                end 
                               
                                fprintf('ERROR: Non-numeric value found at A command a location (%s).  ID %s.\n', token_x, id_string);   
                                element = [];
                                return;
                           elseif ~isNumber(token_b)
                                id_string = 'unknown id';
                               
                                for id_search_count = 1:length(node.Attributes)
                                    if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                        id_string = node.Attributes{id_search_count}.Value;
                                    end
                                end 
                               
                                fprintf('ERROR: Non-numeric value found at A command b location (%s).  ID %s.\n', token_y, id_string);   
                                element = [];
                                return;
                           elseif ~isNumber(token_alpha)
                                id_string = 'unknown id';
                               
                                for id_search_count = 1:length(node.Attributes)
                                    if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                        id_string = node.Attributes{id_search_count}.Value;
                                    end
                                end 
                               
                                fprintf('ERROR: Non-numeric value found at A command alpha location (%s).  ID %s.\n', token_y, id_string);   
                                element = [];
                                return;
                           elseif ~isNumber(token_large_flag)
                                id_string = 'unknown id';
                               
                                for id_search_count = 1:length(node.Attributes)
                                    if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                        id_string = node.Attributes{id_search_count}.Value;
                                    end
                                end 
                               
                                fprintf('ERROR: Non-numeric value found at A command large flag location (%s).  ID %s.\n', token_y, id_string);   
                                element = [];
                                return;
                           elseif ~isNumber(token_sweep_flag)
                                id_string = 'unknown id';
                               
                                for id_search_count = 1:length(node.Attributes)
                                    if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                        id_string = node.Attributes{id_search_count}.Value;
                                    end
                                end 
                               
                                fprintf('ERROR: Non-numeric value found at A command sweep location (%s).  ID %s.\n', token_y, id_string);   
                                element = [];
                                return;
                           elseif ~isNumber(token_x1)
                                id_string = 'unknown id';
                               
                                for id_search_count = 1:length(node.Attributes)
                                    if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                        id_string = node.Attributes{id_search_count}.Value;
                                    end
                                end 
                               
                                fprintf('ERROR: Non-numeric value found at A command x1 location (%s).  ID %s.\n', token_y, id_string);   
                                element = [];
                                return;
                           elseif ~isNumber(token_y1)
                                id_string = 'unknown id';
                               
                                for id_search_count = 1:length(node.Attributes)
                                    if (strcmp(node.Attributes{id_search_count}.Name, 'id'))
                                        id_string = node.Attributes{id_search_count}.Value;
                                    end
                                end 
                               
                                fprintf('ERROR: Non-numeric value found at A command y1 location (%s).  ID %s.\n', token_y, id_string);   
                                element = [];
                                return;
                           end      
                           
                           
                           
           
                           token_x0 = element.data(size(element.data,1),1);
                           token_y0 = element.data(size(element.data,1),2);
                           token_x1 = str2num(token_x1);
                           token_y1 = str2num(token_y1);
                           token_a = str2num(token_a);
                           token_b = str2num(token_b);
                           token_alpha = str2num(token_alpha);
                           token_large_flag = str2num(token_large_flag);
                           token_sweep_flag = str2num(token_sweep_flag);
                           
                           % convert to absolute
                           if (draw_state == 'a')
                               token_x1 = token_x1 + token_x0;
                               token_y1 = token_y1 + token_y0;                            
                           end
 
                           
                          element.data = [element.data; CalculateEllipseCurveSeries(token_x0, token_y0, token_x1, token_y1, token_a, token_b, token_alpha, token_sweep_flag, token_large_flag)];
                           
                           
                                                    
                     
                           
                       end
                          
                       
                   end
                   

               end
                   
           else
               % nothing left
               element = [];
               return;   
           end            
           
                   
       end                
   end 

 element.data = ((transform)*( [element.data'; ones(1,size(element.data,1))] ))';
    
end



function element = process_rect(node)
    
    
    element = [];

	transform = [1 0 0
                 0 1 0
                 0 0 1];
                 
    x = 0;
    y = 0;
    width = 0;
    height = 0;
    
    for (i = 1:length(node.Attributes))
        
       if (strcmp(node.Attributes{i}.Name, 'transform'))       
   		   % found transform so change default
			
           string = strtrim(node.Attributes{i}.Value); %remove leading and trailing space
           string = strrep(string, ',', ' '); %replace commas with space

	       transform = process_transform(string, transform);

           


       elseif (strcmp(node.Attributes{i}.Name, 'width'))
           width = str2num(strtrim(node.Attributes{i}.Value)); 
       
       elseif (strcmp(node.Attributes{i}.Name, 'height'))
           height = str2num(strtrim(node.Attributes{i}.Value));
           
       elseif (strcmp(node.Attributes{i}.Name, 'x'))
           x = str2num(strtrim(node.Attributes{i}.Value));            
    
       elseif (strcmp(node.Attributes{i}.Name, 'y'))
           y = str2num(strtrim(node.Attributes{i}.Value));            
       end                
   end 

   element.data = [x y
                   x+width y
                   x+width y+height
                   x y+height
                   x y];
                   
    element.data = ((transform)*( [element.data'; ones(1,size(element.data,1))] ))';                   
    
end

function element = process_circle(node)
    
    
    element = [];

	transform = [1 0 0
                 0 1 0
                 0 0 1];
                 
    cx = 0;
    cy = 0;
    r = 0;
    
    for (i = 1:length(node.Attributes))
        
       if (strcmp(node.Attributes{i}.Name, 'transform'))       
   		   % found transform so change default
			
           string = strtrim(node.Attributes{i}.Value); %remove leading and trailing space
           string = strrep(string, ',', ' '); %replace commas with space

	       transform = process_transform(string, transform);

           


       elseif (strcmp(node.Attributes{i}.Name, 'cx'))
           cx = str2num(strtrim(node.Attributes{i}.Value)); 
       
       elseif (strcmp(node.Attributes{i}.Name, 'cy'))
           cy = str2num(strtrim(node.Attributes{i}.Value));
           
       elseif (strcmp(node.Attributes{i}.Name, 'r'))
           r = str2num(strtrim(node.Attributes{i}.Value));                        
       end                
   end 
   
   theta = linspace(0, 2*pi, 20)';

   element.data = [cx+r*cos(theta) cy+r*sin(theta)];
                   
   element.data = ((transform)*( [element.data'; ones(1,size(element.data,1))] ))';                   
    
end

function element = process_ellipse(node)
    
    
    element = [];

	transform = [1 0 0
                 0 1 0
                 0 0 1];
                 
    cx = 0;
    cy = 0;
    rx = 0;
    ry = 0;
    
    for (i = 1:length(node.Attributes))
        
       if (strcmp(node.Attributes{i}.Name, 'transform'))       
   		   % found transform so change default
			
           string = strtrim(node.Attributes{i}.Value); %remove leading and trailing space
           string = strrep(string, ',', ' '); %replace commas with space

	       transform = process_transform(string, transform);

           


       elseif (strcmp(node.Attributes{i}.Name, 'cx'))
           cx = str2num(strtrim(node.Attributes{i}.Value)); 
       
       elseif (strcmp(node.Attributes{i}.Name, 'cy'))
           cy = str2num(strtrim(node.Attributes{i}.Value));
           
       elseif (strcmp(node.Attributes{i}.Name, 'rx'))
           rx = str2num(strtrim(node.Attributes{i}.Value));                        
           
       elseif (strcmp(node.Attributes{i}.Name, 'ry'))
           ry = str2num(strtrim(node.Attributes{i}.Value));                                   
       end                
       
   end 
   
   theta = linspace(0, 2*pi, 20)';

   element.data = [cx+rx*cos(theta) cy+ry*sin(theta)];
                   
   element.data = ((transform)*( [element.data'; ones(1,size(element.data,1))] ))';                   
    
end


function result = isNumber(value)
    result = 0;
    
%     if (max(isdigit(value)) == 1)
%         if (max(isalpha(value) == 0))
%             result = 1;
%         end
%     end
    
    result = length(regexp(value, '^[+-]?(([0-9]+\.?[0-9]*)|([0-9]*\.[0-9]+))([eE][+-]?[0-9]+)?$'));
end


function curve_data = CalculateEllipseCurveSeries(x0, y0, x1, y1, a, b, alpha, sweep_flag, large_arc_flag)
    
	curve_data = [];

	if ((alpha == 0) && (abs(x1-x0) - 2*a < 1e-4) && (y1-y0 == 0))
		% special case of an elipse with the points at the extremeties.
		fprintf('Special ellipse case...\n');

		cx = (x1+x0)/2;
		cy = (y1+y0)/2;


	    if (x0 < x1)
			theta_step = linspace(pi, 2*pi, 20);
	    else
			theta_step = linspace(0, pi, 20);
	    end

    	% Generate points
    	x = cx + a*cos(theta_step);
    	y = cy + b*sin(theta_step);
    
    	curve_data = [curve_data; x' y'];

	else


        % Calculate cx and cy
        A0 = x0*cos(alpha) + y0*sin(alpha);
        A1 = x1*cos(alpha) + y1*sin(alpha);
        
        B0 = -x0*sin(alpha) + y0*cos(alpha);
        B1 = -x1*sin(alpha) + y1*cos(alpha);
    
        U = -2*a^2*(B1-B0)/(2*(b^2)*(A1-A0));
        V = (a^2*(B0^2-B1^2) + b^2*(A0^2-A1^2) ) / (2*(b^2)*(A1-A0));
        
        
        S = A0 + V;
        L = (b^2)*(S^2) + (a^2)*(B0^2)-(a^2)*(b^2);
        M = -2*(b^2)*S*U - 2*(a^2)*B0;
        N = a^2+(b^2)*(U^2);
        
    
        
     	% Two possible candidates   
        cy_p = (-M + (M^2 -4*L*N)^0.5)/(2*N);
        cy_n = (-M - (M^2 -4*L*N)^0.5)/(2*N);
        
        cx_p = (A1^2 - A0^2 + a^2/b^2*((B1-cy_p)^2 - (B0-cy_p)^2))/(2*(A1-A0));
        cx_n = (A1^2 - A0^2 + a^2/b^2*((B1-cy_n)^2 - (B0-cy_n)^2))/(2*(A1-A0));
    
    	% Calculate angles between the vectors of start to end point and start to each possible cx,cy
        u = [(x1-x0) (y1-y0)];
        u = u/norm(u);
        v = [(cx_p-x0) (cy_p-y0)];
        v = v/norm(v);
        
        angle_p = real(atan2(v(2), v(1)) - atan2(u(2), u(1)));
        
        
        v = [(cx_n-x0) (cy_n-y0)];
        v = v/norm(v);
        angle_n = real(atan2(v(2), v(1)) - atan2(u(2), u(1)));
    
    
    	% Based on the flags, select which ellipse to use
        if ((large_arc_flag == 1) && (sweep_flag == 1));
        	use_p_ellipse = 0;
        elseif ((large_arc_flag == 1) && (sweep_flag == 0));
        	use_p_ellipse = 1;
        elseif ((large_arc_flag == 0) && (sweep_flag == 0));
        	use_p_ellipse = 1;
        else % ((large_arc_flag == 0) && (sweep_flag == 1));
        	use_p_ellipse = 0;
        end
        
        
        if (angle_p > angle_n)
        	if (use_p_ellipse)
        		use_p_ellipse = 0;
        	else
        		use_p_ellipse = 1;
        	end
        end
        
        if (use_p_ellipse)
        	cx = cx_p;
        	cy = cy_p;    
        else
        	cx = cx_n;
        	cy = cy_n;
        end
    
    
    	% Calculate start and end angles
        P = a*cos(alpha);
        Q = -b*sin(alpha);
        
        theta_start = real(asin((x0 - cos(alpha)*cx + sin(alpha)*cy)/(P^2 + Q^2)^0.5) - atan2(P,Q));
        theta_end = real(asin((x1 - cos(alpha)*cx + sin(alpha)*cy)/(P^2 + Q^2)^0.5) - atan2(P,Q));
        
        if (sweep_flag == 0)
        	theta_start = -theta_start;
        	theta_end = -theta_end;
        end

        if (large_arc_flag)
            if (sweep_flag == 0)
    			if (abs(theta_start-theta_end) < (pi - 1e-9))
    	    		theta_end = theta_end - 2*pi;
    			end
            else
           if (abs(theta_start-theta_end) < (pi - 1e-9))
    	   			theta_end = theta_end + 2*pi;
    			end
            end
        end

    	% Generate angle sweep
        theta_step = linspace(theta_start, theta_end, 20);
    
    	% Generate points
    	x = real(cos(alpha)*(cx + a*cos(theta_step)) - sin(alpha)*(cy + b*sin(theta_step)));
    	y = real(sin(alpha)*(cx + a*cos(theta_step)) + cos(alpha)*(cy + b*sin(theta_step)));
    
    	curve_data = [curve_data; x' y'];

	end
    



end


function curve_data = CalculateBezierCurveSeries(x0, x1, x2, x3, y0, y1, y2, y3, curve_threshold)

    curve_data = [x0 y0];
    
    
    last_t = 0;
    t = 1;
    finished = 0;
    
    while (finished == 0)
    
        [x y] = CalculateBezierCurve(x0, x1, x2, x3, y0, y1, y2, y3, t);
        [x_test y_test] = CalculateBezierCurve(x0, x1, x2, x3, y0, y1, y2, y3, (t-last_t)/2+last_t);
    
        u = [x-curve_data(size(curve_data,1),1)  y-curve_data(size(curve_data,1),2)];
        v = [x_test-curve_data(size(curve_data,1),1)  y_test-curve_data(size(curve_data,1),2)];

        angle = acos(dot(u,v)/(norm(u)*norm(v)));
        
        if (angle < curve_threshold)
           curve_data = [curve_data; x y];
           
           if (t == 1)
               finished = 1;
           else
               last_t = t;
               t = 1;
           end
        else
           t = (t-last_t)/2+last_t;
        end
    
    end
    
    curve_data = curve_data(2:size(curve_data,1),:);
end


function [x y] = CalculateBezierCurve(x0, x1, x2, x3, y0, y1, y2, y3, t)

    x = ((1-t)^3)*x0 + (3*((1-t)^2 )*t)*x1 + (3*(1-t)*t^2)*x2 + (t^3)*x3;
    y = ((1-t)^3)*y0 + (3*((1-t)^2 )*t)*y1 + (3*(1-t)*t^2)*y2 + (t^3)*y3;
    
end


function transform = process_transform(string, current_transform)

	transform = current_transform;

	if (strcmp(string(1:6), 'matrix'))
		string = string(8:size(string,2)-1);

		token_index = [strfind(string, ' ') (length(string)+1)];

		transform(1,1) = str2num(string(1:token_index(1)-1));
		transform(2,1) = str2num(string(token_index(1)+1:token_index(2)-1));
		transform(1,2) = str2num(string(token_index(2)+1:token_index(3)-1));
		transform(2,2) = str2num(string(token_index(3)+1:token_index(4)-1));
		transform(1,3) = str2num(string(token_index(4)+1:token_index(5)-1));
	    transform(2,3) = str2num(string(token_index(5)+1:size(string,2)));

    elseif (strcmp(string(1:9), 'translate'))
		string = string(11:size(string,2)-1);

		token_index = [strfind(string, ' ') (length(string)+1)];

		transform(1,3) = str2num(string(1:token_index(1)-1));
		transform(2,3) = str2num(string(token_index(1)+1:size(string,2)));

    elseif (strcmp(string(1:5), 'scale'))
		fprintf('Scale transform not yet implemented.\n');

    elseif (strcmp(string(1:5), 'skewx'))
		fprintf('Skew X transform not yet implemented.\n');

    elseif (strcmp(string(1:5), 'skewy'))
		fprintf('Skey Y transform not yet implemented.\n');

	else
		fprintf('Unknown transform found: %s\n', string);
	end

end