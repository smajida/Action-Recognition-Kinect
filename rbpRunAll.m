function rbpRunAll(tagmode)

% read samples from disk
[samples class_names_list simple_action_name_list subject_names_list] = readUNComplexActionsDataset;
%[samples tags unique_tags] = tagUNComplexActionsDataset(samples);

if tagmode
    class_names_list = unique_tags;
end

number_subjects = numel(subject_names_list);
number_classes = numel(simple_action_name_list);
CM = zeros(number_classes, number_classes, number_subjects);
models = cell(number_subjects,1);
centers = cell(number_subjects,1);
pr = cell(number_subjects,1);
prompt_ans = 'f';
while ((prompt_ans ~='y')&&(prompt_ans ~='n'))
    prompt_ans = input('Use stored pose Codebooks? (y/n): ','s');
end
for subidx = 1:number_subjects
    [centers{subidx}, models{subidx}, scores, CM_sub, pr{subidx}] = ...
        rbpRunOneSubjectSimpleAction(samples, subject_names_list, subidx, ...
        class_names_list, tagmode, simple_action_name_list,  prompt_ans);
    CMTL(:, :, subidx) = CM_sub.topleft;
    CMBL(:, :, subidx) = CM_sub.botleft;
    CMTR(:, :, subidx) = CM_sub.topright;
    CMBR(:, :, subidx) = CM_sub.botright;
    %CM(:, :, subidx) = CM_sub;
end
% get average confusion matrix
cumCMTL = sum(CMTL,3);
cumCMBL = sum(CMBL,3);
cumCMTR = sum(CMTR,3);
cumCMBR = sum(CMBR,3);
%
handClasses = size(cumCMTL);
feetClasses = size(cumCMBL);
%cumCM = sum(CM,3);
overallCMTL = cumCMTL ./ repmat(sum(cumCMTL,2), 1,handClasses(1,1));
overallCMBL = cumCMBL ./ repmat(sum(cumCMBL,2), 1,feetClasses(1,1));
overallCMTR = cumCMTR ./ repmat(sum(cumCMTR,2), 1,handClasses(1,1));
overallCMBR = cumCMBR ./ repmat(sum(cumCMBR,2), 1,feetClasses(1,1));
%overallCM = cumCM ./ repmat(sum(cumCM,2), 1,number_classes);
overallAccTL = mean(diag(overallCMTL));
overallAccBL = mean(diag(overallCMBL));
overallAccTR = mean(diag(overallCMTR));
overallAccBR = mean(diag(overallCMBR));
%overallAcc = mean(diag(overallCM));
fprintf('Average diagonal = %f\n', overallAcc);
figure;
confMatrixShow(overallCMBR,{models{1}(:).botright.class_name}, {'FontSize',11});
