filenum = '330';

filename = ['frames\caseFeedbackDemo4\runFeedbackDemo4_trial0_000', filenum, '.fig'];
output = ['frames\svgFeedbackDemo\runFeedbackDemo4_trial0_000', filenum, '.svg'];

open(filename)
saveas(1, output)
close all