function tbl = combinations(arr1, arr2)
% Pairwise Combinations of strings
% This function is built-in to MATLAB 2023a
    reshape(arr1.', 1, []);
    reshape(arr2.', 1, []);

    sz1 = max(size(arr1));
    sz2 = max(size(arr2));

    tbl = strings(sz1 * sz2, 2);
    idx = 1;
    for i = 1:max(size(arr1))
        for j = 1:max(size(arr2))
            tbl(idx, 1) = arr1(i);
            tbl(idx, 2) = arr2(j);
            idx = idx + 1;
        end
    end
end