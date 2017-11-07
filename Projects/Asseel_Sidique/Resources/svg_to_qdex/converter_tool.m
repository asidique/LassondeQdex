clc;
close all;

Scale_Factor = 1/140;

%include svg_to_qdex


elements = svg_to_qdex('field2.svg', 3/180*pi);


% merge into one large series
total_elements = 0;
repeat_flag = 0

fid = fopen('field2.csv', 'w');
fic = fopen('field2_color.csv', 'w');
      

for i = 1:size(elements,2)

	elements(i).data = elements(i).data*Scale_Factor;

    for j = 1:size(elements(i).data, 1)
        
        if repeat_flag == 1
           fprintf(fid, '%f,%f\n', elements(i).data(j,1),  elements(i).data(j,2) );
           fprintf(fic, 'transparent\n');
           repeat_flag = 0;  
        end

		fprintf(fid, '%f,%f\n', elements(i).data(j,1),  elements(i).data(j,2) ); 
        fprintf(fic, 'black\n');  
       	total_elements = total_elements + 1;
    end

    if ((i == size(elements,2)) && (j == size(elements(i).data,1) ) )

    else
		% repeat last element
	    fprintf(fid, '%f,%f\n', elements(i).data(j,1),  elements(i).data(j,2) );
        fprintf(fic, 'transparent\n');
        repeat_flag = 1;     
	    total_elements = total_elements + 2;
    end
end

fclose(fid);

% plot
fid = figure;
total_elements = 0;

for i = 1:length(elements)
    plot(elements(i).data(:,1), elements(i).data(:,2), 'k-o');
    hold on;
    
    total_elements = total_elements + length(elements(i).data);
end
    
hold off;
axis equal; 

fprintf('Finished logo image.\n\n');


fprintf('Set plot size to %d elements.\n\n', total_elements);