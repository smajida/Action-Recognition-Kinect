function models = rbpTrainLinearSVMSimpleAction(training_samples, simple_action_name_list, svm_c, tagmode)

if ~exist('tagmode', 'var') || isempty(tagmode)
    tagmode = 0;
end

if ~exist('svm_c', 'var') || isempty(svm_c)
    svm_c = 1;
end

%if ~exist('simple_action_name_list', 'var') || isempty(simple_action_name_list)
%    simple_action_name_list = unique({training_samples(:).class_name});
%end

number_parts = size(struct2cell(training_samples));

idx = {'topleft', 'botleft', 'topright', 'botright'};

for i = 1 : number_parts(1,1)
    
    number_samples = numel(training_samples.(idx{i}));
    number_classes = numel(simple_action_name_list);
    
    % features are concatenated bag-of-poses from each body part
    %training_features = cell2mat(arrayfun(@(x) cell2mat(x.bop), ...
    %    training_samples, 'UniformOutput', false)');
    
    models(number_classes).(idx{i}).svm_model = [];
    models(number_classes).(idx{i}).class_name = [];
    
    for cidx = 1:number_classes
        clearvars training_labels;
        %[related cut_training_samples] = findRelated(simple_action_name_list(cidx), training_samples);
        training_features = cell2mat({training_samples.(idx{i}).bop}');
        
        if tagmode
            % get binary labels for this tag
            all_active_tags = cell2mat({training_samples(:).active_tags}');
            training_labels = all_active_tags(:,cidx);
        else
            % get binary labels for this class
            %training_labels = double(strcmp({training_samples(:).class_name}, ...
            %    simple_action_name_list{cidx}))';
            
            for j = 1:number_samples
                training_labels(j) =  ismember(1,strcmp(training_samples.(idx{i})(j).action, simple_action_name_list{cidx}));
            end
        end
        
        training_labels = +training_labels';
        % train a linear SVM
        % TODO: try L1 regularization!
        svm_w = sum(1-training_labels)/sum(training_labels);
        svm_string = sprintf('-t 0 -c %d -q -w1 %f', svm_c, svm_w);
        svm_model = svmtrain(training_labels, training_features, svm_string);
        
        models(cidx).(idx{i}).svm_model = svm_model;
        models(cidx).(idx{i}).class_name = simple_action_name_list{cidx};
        
        % compute accuracy in training
        [pl, acc, dv] =  svmpredict(training_labels, training_features, ...
            svm_model);
        if svm_model.Label(1)==0
            dv = -dv;
        end
        %[precision recall ap thr] = precrec2(training_labels == 1, dv, 1);
        %if 0
        %    figure(cidx);
        %    plot(dv.*(2*training_labels-1));
        %    ylim([-2 2]);
        %    title(class_names{cidx})
        %end
    end
end

