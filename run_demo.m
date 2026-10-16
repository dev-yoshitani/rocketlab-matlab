function result = run_demo()
startup_project(); [v,c]=rocketlab.demo_config(); result=run_case(v,c);
fprintf('検証用デモ完了: %s\n',result.outputFolder);
fprintf('選択した評価: %s | 全機判定: %s\n',result.selectedEvaluationStatus,result.wholeVehicleStatus);
end
