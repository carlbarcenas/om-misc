% Brian Ouellette
% ECE 4893A
% gth677b
% HW2 09/17/2007
% Loads in a model, renders it as triangles in a MATLAB plot and applies various effects to it.
% Scaling, rotation, translation, backface culling, z-sorting, emissive/ambient/specular/diffuse lighting models

% Usage: Running this script will display the shuttle and spin it around a
% few times. To disable spin just remove the for i = 1:100 and the last end

clear;
objectRotation = [10 0 0]; %[x y z] degree rotation from starting position
% The loading and stuff could be moved out of the loop but the slowdown is
% helpful for seeing the object
for i = 1:100
    clf % clear figure

    filepath = 'shuttle_breneman_whitfield.raw';
    lightPos = [.5 0 -1]; % This is the location of the light source relative to the object being at [0 0 0]
    lightColor = [1 1 1]; % white
    ambientColor = [200/255 200/255 0]; % yellow
    emissiveColor = [.5 .5 .5]; % gray
    materialColor = [0/255 163/255 160/255]; % light gray
    cameraPos = [0 0 0]; % Initial camera position in world coordinates
    cameraOrientation = [0 1 1]; % [x y z] (vector from cameraPos in direction camera is pointing) *this can't be [0 0 0], it wouldn't make sense
    objectScale = [2 2 2]; % [x y z] individual dimensions scaling
    objectPos = [0 20 20]; % [x y z] the objects position in the world coordinates. If you want to see the object make sure it's where the camera is pointing!
    frustrum = [1 100]; % [front rear] Only the front frustrum is used in this example as only one object is present.
    FOV = [4/2 3/2]; % [horizontal vertical] This defines the Matlab axes. If the object is too small make them smaller, too big larger
    
    % Read in the file
    vertices = dlmread(filepath);
    numVertices = size(vertices, 1); % Get the number of polygons we have to render
    vertices = [vertices(:, 1:3) ones(numVertices, 1) vertices(:, 4:6) ones(numVertices, 1) vertices(:, 7:9) ones(numVertices, 1) ]; % Add in columns of 1s for easy matrix math

    % Scale the model
    scaleMat = eye(4);
    scaleMat(1,1) = objectScale(1);
    scaleMat(2,2) = objectScale(2);
    scaleMat(3,3) = objectScale(3);

    % Rotate the model
    rotMatX = [1 0                        0                        0; ...
               0 cosd(objectRotation(1))  sind(objectRotation(1))  0; ...
               0 -sind(objectRotation(1)) cosd(objectRotation(1))  0; ...
               0 0                        0                        1];

    rotMatY = [cosd(objectRotation(2)) 0 -sind(objectRotation(2)) 0; ...
               0                       1 0                        0; ...
               sind(objectRotation(2)) 0 cosd(objectRotation(2))  0; ...
               0                       0 0                        1];

    rotMatZ = [cosd(objectRotation(3))  sind(objectRotation(3))  0 0; ...
               -sind(objectRotation(3)) cosd(objectRotation(3))  0 0; ...
               0                        0                        1 0; ...
               0                        0                        0 1];

    % Translate model coordinates to world coordinates
    transMat = eye(4);
    transMat(4, 1:3) = objectPos;

    % Translate camera coordinates to origin
    transMat(4, 1:3) = transMat(4, 1:3) - cameraPos;

    % Create our master translation/scaling/rotation matrix
    transMat = scaleMat*rotMatX*rotMatY*rotMatZ*transMat;

    % Apply the transformation matrix to each set of vertices
    for index1 = 1:numVertices
        vertices(index1, 1:4) = vertices(index1, 1:4)*transMat;
        vertices(index1, 5:8) = vertices(index1, 5:8)*transMat;
        vertices(index1, 9:12) = vertices(index1, 9:12)*transMat;
    end

    % Translate camera angle to the ZY plane first
    cameraOrientationUnit = cameraOrientation(1:3)./norm(cameraOrientation(1:3)); % Normalize to a unit vector
    if(sum(cameraOrientation(1:2)) == 0)
        zRotation = 1;
    else
        cameraOrientationUnitXY = cameraOrientation(1:2)./norm(cameraOrientation(1:2)); % Normalize the XY projection to a unit vector
        zRotation = dot([0 1 0], [cameraOrientationUnitXY 0]); % Look at XY plane, find angle to +Y, rotate about Z by angle
    end
    xRotation = dot([0 0 1], cameraOrientationUnit); % Find angle between vector and Z, that will be our X rotation AFTER we rotate about Z
    % Create the rotation matrix for the Z rotation
    transMat = [zRotation             sin(acos(zRotation)) 0 0; ...
                -sin(acos(zRotation)) zRotation            0 0; ...
                0                     0                    1 0; ...
                0                     0                    0 1];
    if(cameraOrientationUnit(1) < 0) % Since dot product returns the cos(theta) we need to differentiate between sectors
        transMat(1, 2) = sin(-acos(zRotation));
        transMat(2, 1) = -sin(-acos(zRotation));
    end
    % So far we've created the translation matrix for the Z rotation, now we
    % need to rotate about X, we can just combine the matrices
    transMat = transMat*[1 0                     0                    0; ...
                         0 xRotation             sin(acos(xRotation)) 0; ...
                         0 -sin(acos(xRotation)) xRotation            0; ...
                         0 0                     0                    1];
    % And our final multiply does all rotation for us
    cameraOrientationUnit = [cameraOrientationUnit 1]*transMat;
    % This unit vector should always end as [0 0 1 1], for checking/testing
    % It works so let's apply the transMat to every vertex
    for index1 = 1:numVertices
        vertices(index1, 1:4) = vertices(index1, 1:4)*transMat;
        vertices(index1, 5:8) = vertices(index1, 5:8)*transMat;
        vertices(index1, 9:12) = vertices(index1, 9:12)*transMat;
    end

    % Do Z-sorting
    % First attempt was to use an average z value for sorting but it doesn't work well
    % Second attempt used the max z value for sorting and that worked out better
    for index1 = 1:numVertices
        %vertices(index1, 13) = (vertices(index1, 3) + vertices(index1, 6) + vertices(index1, 9))/3; % First attempt (average)
        vertices(index1, 13) = max([vertices(index1, 3) vertices(index1, 6) vertices(index1, 9)]); % Second attempt (max)
    end
    % Now sort by the obtained metric
    vertices = sortrows(vertices, -13);

    % Backface culling
    index1 = 1;
    while(index1 <= numVertices)
        % First we have to calculate the surface normal of the polygon
        v1 = vertices(index1, 5:7) - vertices(index1, 1:3);
        v2 = vertices(index1, 9:11) - vertices(index1, 1:3);
        vertices(index1, 13:15) = cross(v1, v2); % store the surface normal for the polygon for later
        vertices(index1, 13:15) = vertices(index1, 13:15)./norm(vertices(index1, 13:15)); % make sure it's a unit vector
        if(dot([0 0 1], vertices(index1, 13:15)) > 0) % if it's facing away from the camera then cull it
            vertices(index1, :) = [];
            numVertices = numVertices - 1; % bookkeeping on our variables
            index1 = index1 - 1;
        end
        index1 = index1 + 1;
    end

    % Next we'll implement perspective projection on the vertices so that
    % things far away look smaller.
    transMat = eye(4);
    transMat(3, 4) = 1/1;
    transMat(4, 4) = 0;
    % Apply the perspective projection
    for index1 = 1:numVertices
        vertices(index1, 1:4) = vertices(index1, 1:4)*transMat;
        vertices(index1, 1:3) = vertices(index1, 1:3)./vertices(index1, 4);
        vertices(index1, 5:8) = vertices(index1, 5:8)*transMat;
        vertices(index1, 5:7) = vertices(index1, 5:7)./vertices(index1, 8);
        vertices(index1, 9:12) = vertices(index1, 9:12)*transMat;
        vertices(index1, 9:11) = vertices(index1, 9:11)./vertices(index1, 12);
    end

    % Apply our frustrum
    index1 = 1;
    while(index1 <= numVertices)
        % For now we'll just use a hard frustrum test
        % Any triangle that crosses the front frustrum is clipped
        % There isn't a need in this example to repeat this for the rear
        % frustrum but it would be essentially the same
        if(vertices(index1, 3) < frustrum(1) || vertices(index1, 3) < frustrum(1) || vertices(index1, 3) < frustrum(1))
            vertices(index1, :) = [];
            numVertices = numVertices - 1;
        end
        index1 = index1 + 1;
    end

    % Apply lighting conditions
    lightPos = -lightPos./norm(lightPos); % make sure the vector is normalized
    S = 1; % shininess

    for index1 = 1:numVertices
        % To create a vector between our eye and the polygon we get the
        % average position of the polygon
        polygonPosition = [(vertices(index1, 1) + vertices(index1, 5) + vertices(index1, 9))/3 ...
                           (vertices(index1, 2) + vertices(index1, 6) + vertices(index1, 10))/3 ...
                           (vertices(index1, 3) + vertices(index1, 7) + vertices(index1, 11))/3];
        % Create the halfway vector between the light and our eye
        H = (-lightPos + polygonPosition)./norm(-lightPos + polygonPosition);
        % Different aspects of light can be weighted differently
        vertices(index1, 16:18) = (.1/1)*emissiveColor + ... % emissive lighting
                                  (.1/1)*ambientColor + ... % ambient lighting
                                  (.7/1)*max(dot(-1*lightPos, vertices(index1, 13:15)), 0)*(materialColor.*lightColor) + ... % diffuse lighting
                                  (.1/1)*max(dot(vertices(index1, 13:15), H), 0)^S*(materialColor.*lightColor); % specular lighting
    end

    set(0, 'DefaultPatchEdgeColor', 'none');
    axis([-FOV(1)/2 FOV(1)/2 -FOV(2)/2 FOV(2)/2])
    for index1 = 1:numVertices
        patch(vertices(index1, 1:4:9),vertices(index1, 2:4:10), vertices(index1, 16:18));
    end
    pause(.03)
    objectRotation(1) = objectRotation(1) + 10;
    objectRotation(2) = objectRotation(2) + 10;
end






