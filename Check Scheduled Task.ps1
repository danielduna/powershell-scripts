﻿Get-ScheduledTask | Get-ScheduledTaskInfo | Select TaskName,TaskPath,LastRunTime, LastTaskResult,NextRunTime,NumberofMissedRuns | Sort-Object -Property TaskName