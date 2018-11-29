% Calculates distance between 2 bounding box
function dist = bbox_dist(G, P)
            if isempty(P) || isempty(G)
                dist = NaN;
                return;
            end
            px = P(:,1) + floor(P(:,3)/2);
            py = P(:,2) + floor(P(:,4)/2);
            
            % center of gt
            gx = G(:,1) + floor(G(:,3)/2);
            gy = G(:,2) + floor(G(:,4)/2);
            
            tx = (gx - px);
            ty = (gy - py);
            g=horzcat(gx,gy);
            p=horzcat(px,py);
            dist=[];
            for i = 1:size(g,1)
                dist(i,1) = pdist([g(i,:);p(i,:)],'euclidean');
            end
end