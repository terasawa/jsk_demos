#!/usr/bin/env roseus

(load "package://drc_task_common/euslisp/vehicle/vehicle-executive-utils.l")

(ros::roseus-add-msgs "drc_com_common")
(ros::roseus "vehicle_fc_executive")

(setq *latest-goal-handle-angle* nil)
(setq *latest-estimated-handle-angle* nil)
(setq *latest-step* nil)
(setq *latest-min-step* nil)
(setq *latest-max-step* nil)
(setq *latest-handle-mode* nil)
(setq *latest-accel-mode* nil)

(defun ocs-message-callback (msg)
  (print msg)
  (let (tmp-msg)
    (setq tmp-msg (make-msg-from-tunnel msg :handle_cmd std_msgs::Float64))
    (ros::publish "/drive/operation/handle_cmd" tmp-msg)
    (setq tmp-msg (make-msg-from-tunnel msg :accel_cmd std_msgs::Float64))
    (ros::publish "/drive/operation/accel_cmd" tmp-msg)
    )
  )

(defun goal-handle-angle-callback (msg)
  (setq *latest-goal-handle-angle* (send msg :data))
  )
(defun estimated-handle-angle-callback (msg)
  (setq *latest-estimated-handle-angle* (send msg :data))
  )
(defun step-callback (msg)
  (setq *latest-step* (send msg :data))
  )
(defun min-step-callback (msg)
  (setq *latest-min-step* (send msg :data))
  )
(defun max-step-callback (msg)
  (setq *latest-max-step* (send msg :data))
  )
(defun handle-mode-callback (msg)
  (print (send msg :data))
  (setq *latest-handle-mode* (convert-mode-to-uint8 (send msg :data)))
  )
(defun accel-mode-callback (msg)
  (setq *latest-accel-mode* (convert-mode-to-uint8 (send msg :data)))
  )

(defun main-spin-once ()
  (let ((msg (instance drc_com_common::VehicleFC2OCSSmall :init)))
    (when *latest-goal-handle-angle*
      (send msg :goal_handle_angle *latest-goal-handle-angle*)
      )
    (when *latest-estimated-handle-angle*
      (send msg :estimated_handle_angle *latest-estimated-handle-angle*)
      )
    (when *latest-step*
      (send msg :step *latest-step*)
      )
    (when *latest-min-step*
      (send msg :min_step *latest-min-step*)
      )
    (when *latest-max-step*
      (send msg :max_step *latest-max-step*)
      )
    (when *latest-handle-mode*
      (send msg :handle_mode *latest-handle-mode*)
      )
    (when *latest-accel-mode*
      (send msg :accel_mode *latest-accel-mode*)
      )
    (ros::publish "/fc_to_ocs_vehicle/input" msg)
    )
  )

;; for ueda tunnel
(ros::advertise "/fc_to_ocs_vehicle/input" drc_com_common::VehicleFC2OCSSmall)
(ros::subscribe "/fc_from_ocs_vehicle/output" drc_com_common::VehicleOCS2FCSmall #'ocs-message-callback)

;; message to driving-controller
(ros::advertise "/drive/operation/handle_cmd" std_msgs::Float64 1)
(ros::advertise "/drive/operation/accel_cmd" std_msgs::Float64 1)

;; message from driving-controller
(ros::subscribe "/drive/controller/goal_handle_angle" std_msgs::Float32 #'goal-handle-angle-callback)
(ros::subscribe "/drive/controller/estimated_handle_angle" std_msgs::Float32 #'estimated-handle-angle-callback)
(ros::subscribe "/drive/controller/step" std_msgs::Float32 #'step-callback)
(ros::subscribe "/drive/controller/min_step" std_msgs::Float32 #'min-step-callback)
(ros::subscribe "/drive/controller/max_step" std_msgs::Float32 #'max-step-callback)
(ros::subscribe "/drive/controller/handle_mode" std_msgs::String #'handle-mode-callback)
(ros::subscribe "/drive/controller/accel_mode" std_msgs::String #'accel-mode-callback)

(ros::rate 10)
(while (ros::ok)
  (ros::spin-once)
  (main-spin-once)
  (ros::sleep))