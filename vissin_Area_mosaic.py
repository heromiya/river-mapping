#!/usr/bin/env python
# -*- coding: UTF-8 -*-
"""
  @CreateTime:   2018-01-26T16:50:00+09:00
  @Email:  guangmingwu2010@gmail.com
  @Copyright: go-hiroaki
  @License: MIT
"""
import os, glob
import gc
import argparse
import torch
import itertools
import numpy as np
import pandas as pd
from utils import metrics
from skimage.io import imsave, imread
import pickle
import json

from utils import vision
from utils.runner import load_checkpoint
import skimage.exposure as exposure

from skimage.morphology import skeletonize

from tqdm import tqdm as pbar

Checkpoint_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'checkpoint')
Result_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'result_mosaic_veg')
Utils_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'utils')
Log_name = 'area_binary_log.csv'


def rescale(img):
    percent = 2
    pLow, pHigh = np.percentile(img[img>0], (percent, 100-percent))
    img_rescaled = exposure.rescale_intensity(img, in_range=(pLow, pHigh))
    return img_rescaled

def load_recent_checkpoint(checkpoint_dir):
    list_of_models = glob.glob(os.path.join(checkpoint_dir, '*.pth'))
    latest_model = max(list_of_models, key=os.path.getctime)
    model_name = os.path.basename(latest_model)
    return model_name


def save_log(log_results):
    columns = ['image', 'model',
               'over_accuracy', 'precision', 'recall', 'f1score', 'IoU', 'Kappa']
    data = log_results

    if not os.path.exists(os.path.join(Result_DIR, 'logs')):
        os.makedirs(os.path.join(Result_DIR, 'logs'))

    if os.path.exists(os.path.join(Result_DIR, 'logs', Log_name)):
        logs = pd.read_csv(os.path.join(Result_DIR, 'logs', Log_name))
        logs_new = pd.DataFrame(data=data, columns=columns)

        logs = logs.append(logs_new)
    else:
        logs = pd.DataFrame(data=data, columns=columns)

    logs.to_csv("{}/logs/{}".format(Result_DIR, Log_name), index=False, float_format='%.3f')


def main(args):
    """
    Multi-house comparison using different methods
      args:
        .checkpoints: pretrained pytorch model
        .data: data path for prediction
    """
    Data_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'src', args.data)
    Anno_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'src', args.data + '_anno')

    if args.cuda and not torch.cuda.is_available():
        raise ValueError("GPUs are not available, please run at cpu mode")
    if not os.path.exists(os.path.join(Result_DIR, 'area-binary')):
        os.makedirs(os.path.join(Result_DIR, 'area-binary'))

    # read and align image
    if args.test_all == True:
        img_names = [os.path.basename(full_name) for full_name in glob.glob(Data_DIR + '/*')]
    else:
        img_names = args.img_names

    if args.load_recent:
        checkpoint = load_recent_checkpoint(Checkpoint_DIR)
        args.checkpoints = []
        args.checkpoints.append(checkpoint)

    mosaic_dict = json.load(open('./temp/mosaic_dict.json'))

    mosaic_dates = list(mosaic_dict.keys())

    for img_name in pbar(img_names):
        if img_name.endswith('.tfw') or img_name.endswith('.xml'):
            continue
        if img_name.split('.')[0] not in mosaic_dates:
            print('%s not in date dictionary'%(img_name.split('.')[0]))
            continue
        landsat_idx = mosaic_dict[img_name.split('.')[0]]

        print("===> Image {}/{}: {},    \r".format((img_names.index(img_name) + 1), \
                                                   (len(img_names)), img_name, ))
        anno_name = img_name
        ANNO = False
        if os.path.exists(Anno_DIR):
            if anno_name in os.listdir(Anno_DIR):
                ANNO = True
        img_path = os.path.join(Data_DIR, img_name)
        src_img = imread(img_path)

        if not args.aster:
            if len(landsat_idx) == 1:
                if ('4' in landsat_idx) or ('5' in landsat_idx) or ('6' in landsat_idx) or ('7' in landsat_idx):
                    src_img_4 = np.expand_dims(src_img[:, :, 3], -1)
                    src_img_5 = np.expand_dims(src_img[:, :, 4], -1)
                    src_img_3 = np.expand_dims(src_img[:, :, 2], -1)

                    img_new = np.concatenate((src_img_4, src_img_5, src_img_3), -1)
                    src_img = rescale(img_new)
                else:
                    # landsat 8
                    src_img_5 = np.expand_dims(src_img[:, :, 4], -1)
                    src_img_6 = np.expand_dims(src_img[:, :, 5], -1)
                    src_img_4 = np.expand_dims(src_img[:, :, 3], -1)

                    img_new = np.concatenate((src_img_5, src_img_6, src_img_4), -1)
                    src_img = rescale(img_new)
            else:
                # ['7', '8'], based on 7 as well
                # ['5', '7']
                # ['5', '4']
                src_img_4 = np.expand_dims(src_img[:, :, 3], -1)
                src_img_5 = np.expand_dims(src_img[:, :, 4], -1)
                src_img_3 = np.expand_dims(src_img[:, :, 2], -1)

                img_new = np.concatenate((src_img_4, src_img_5, src_img_3), -1)
                src_img = rescale(img_new)
        else:
            if len(landsat_idx) == 1:
                if ('4' in landsat_idx) or ('5' in landsat_idx) or ('6' in landsat_idx) or ('7' in landsat_idx):
                    src_img_4 = np.expand_dims(src_img[:, :, 3], -1)
                    src_img_3 = np.expand_dims(src_img[:, :, 2], -1)
                    src_img_2 = np.expand_dims(src_img[:, :, 1], -1)

                    img_new = np.concatenate((src_img_4, src_img_3, src_img_2), -1)
                    src_img = rescale(img_new)
                else:
                    # landsat 8
                    src_img_5 = np.expand_dims(src_img[:, :, 4], -1)
                    src_img_4 = np.expand_dims(src_img[:, :, 3], -1)
                    src_img_3 = np.expand_dims(src_img[:, :, 2], -1)

                    img_new = np.concatenate((src_img_5, src_img_4, src_img_3), -1)
                    src_img = rescale(img_new)
            else:
                # ['7', '8'], based on 7 as well
                # ['5', '7']
                # ['5', '4']
                src_img_4 = np.expand_dims(src_img[:, :, 3], -1)
                src_img_3 = np.expand_dims(src_img[:, :, 2], -1)
                src_img_2 = np.expand_dims(src_img[:, :, 1], -1)

                img_new = np.concatenate((src_img_4, src_img_3, src_img_2), -1)
                src_img = rescale(img_new)

        if args.border_remain:
            if len(src_img.shape) == 2:
                _img_rows, _img_cols = src_img.shape
            else:
                _img_rows, _img_cols, _img_ch = src_img.shape
            _img_dtype = src_img.dtype
            if _img_rows // args.img_rows != 0:
                _img_rows_new = (_img_rows // args.img_rows + 1) * args.img_rows
            else:
                _img_rows_new = _img_rows
            if _img_cols // args.img_cols != 0:
                _img_cols_new = (_img_cols // args.img_cols + 1) * args.img_cols
            else:
                _img_cols_new = _img_cols
            if len(src_img.shape) == 2:
                img_new = np.empty((_img_rows_new, _img_cols_new), _img_dtype)
            else:
                img_new = np.empty((_img_rows_new, _img_cols_new, _img_ch), _img_dtype)
            img_new[:_img_rows, :_img_cols] = src_img
            src_img = img_new

        if len(src_img.shape) == 2:
            src_img = (np.expand_dims(src_img, -1) / 255)

        x_slices, x_shapes = vision.img_to_slices(
            src_img, args.img_rows, args.img_cols)
        #        print(x_slices.shape)
        x_slices = np.array(x_slices)

        for checkpoint in args.checkpoints:
            # load models
            model = load_checkpoint(checkpoint)
            if args.cuda:
                model.cuda()
            model.eval()
            # predict by batch
            y_preds = []
            steps = x_slices.shape[0] // args.batch_size
            if (x_slices.shape[0] % args.batch_size) == 0:
                step_range = steps
            else:
                step_range = steps + 1
            for step in range(step_range):
                print("Predicting by {} at {}/{} \r".format(checkpoint,
                                                            (step + 1), (step_range)))
                if step < steps:
                    x = x_slices[step *
                                 args.batch_size:(step + 1) * args.batch_size]
                else:
                    x = x_slices[step * args.batch_size:]
                x = (x / 255).transpose((0, 3, 1, 2)).astype('float32')
                x = torch.tensor(x)
                if args.cuda:
                    x = x.cuda()
                # TODO:
                if checkpoint.startswith("SR"):
                    x = x.resize_(32, 3, 112, 112)
                # generate prediction
                y_pred = model(x)
                if args.cuda:
                    y_pred = y_pred.data.cpu().numpy()
                else:
                    y_pred = y_pred.data.numpy()
                y_preds.append(y_pred)
            y_preds = np.concatenate(y_preds)
            results = []
            for i in range(y_preds.shape[0]):
                pred_img = y_preds[i].transpose((1, 2, 0))
                pred_img[pred_img >= 0.5] = 255
                pred_img[pred_img < 0.5] = 0

                if args.target == 'edge':
                    # extract edges from segmentation map
                    pred_img = vision.shift_edge(pred_img, dtype="float32")
                    pred_img = np.argmax(pred_img, axis=-1) * 23
                    pred_img = np.expand_dims(pred_img, -1).astype("uint8")
                    pred_rgb = np.concatenate(
                        [pred_img, pred_img, pred_img], axis=-1)
                results.append(pred_img)
            del y_preds

            # merge slices into image
            result_img = vision.slices_to_img(results, x_shapes)
            del results
            result_img = np.squeeze(result_img)
            name = "{}_area_{}_{}.tif".format(
                os.path.splitext(img_name)[0], args.target, checkpoint.strip('.pth'))

            if args.border_remain:
                result_img = result_img[:_img_rows, :_img_cols]

            if args.centerline:
                image = result_img // 255
                skeleton = skeletonize(image)
                centerline_name = "{}_area_centerline_{}.jpg".format(
                    os.path.splitext(img_name)[0], checkpoint.strip('.pth'))

                imsave(os.path.join(Result_DIR, 'area-binary', centerline_name), skeleton*255)

            imsave(os.path.join(Result_DIR, 'area-binary', name), result_img)
            print("Saving {} ...".format(name))

            if ANNO:
                tar_img = imread(os.path.join(Anno_DIR, anno_name))
                tar_img = tar_img[:result_img.shape[0], :result_img.shape[1]]

                if args.border_remain:
                    _tar_img_dtype = tar_img.dtype
                    # if len(tar_img.shape) == 2:
                    #     tar_img_new = np.empty((_img_rows_new, _img_cols_new), _tar_img_dtype)
                    if len(tar_img.shape) == 2:
                        tar_img_new = np.empty((_img_rows, _img_cols), _tar_img_dtype)

                    else:
                        # _tar_img_ch = tar_img.shape[-1]
                        # tar_img_new = np.empty((_img_rows_new, _img_cols_new, _tar_img_ch), _tar_img_dtype)
                        _tar_img_ch = tar_img.shape[-1]
                        tar_img_new = np.empty((_img_rows, _img_cols, _tar_img_ch), _tar_img_dtype)

                    tar_img_new[:_img_rows, :_img_cols] = tar_img
                    tar_img = tar_img_new

                if len(tar_img.shape) == 2:
                    _tar_img = (np.expand_dims(tar_img, -1) / 255).astype('float32')
                else:
                    _tar_img = (tar_img / 255).astype('float32')

                _tar_img = np.transpose(_tar_img, (2, 0, 1))
                _tar_img = np.expand_dims(_tar_img, 0)

                if len(result_img.shape) == 2:
                    _result_img = (np.expand_dims(result_img, -1) / 255).astype('float32')
                else:
                    _result_img = (result_img / 255).astype('float32')

                _result_img = np.transpose(_result_img, (2, 0, 1))
                _result_img = np.expand_dims(_result_img, 0)

                _result_img = torch.tensor(_result_img)
                _tar_img = torch.tensor(_tar_img)

                oa = metrics.overall_accuracy(_result_img, _tar_img)
                precision = metrics.precision(_result_img, _tar_img)
                recall = metrics.recall(_result_img, _tar_img)
                f1 = metrics.f1_score(_result_img, _tar_img)
                jac = metrics.jaccard(_result_img, _tar_img)
                kappa = metrics.kappa(_result_img, _tar_img)

                log_results = []
                log_result = [img_name, checkpoint]
                perform = [oa, precision, recall, f1, jac, kappa]
                perform = [np.round(perform[i], 3) for i in range(len(perform))]
                log_result.extend(perform)
                log_results.append(log_result)

                save_log(log_results)

                result_mask_img = vision.pair_to_rgb(result_img, tar_img, background="white")
                name = "{}_area_mask_{}_{}.tif".format(
                    os.path.splitext(img_name)[0], args.target, checkpoint.strip('.pth'))

                if args.border_remain:
                    result_mask_img = result_mask_img[:_img_rows, :_img_cols]

                imsave(os.path.join(Result_DIR, 'area-binary', name), result_mask_img)
                print("Saving {} ...".format(name))


if __name__ == "__main__":
    # ====================== parameter initialization ======================= #
    parser = argparse.ArgumentParser(description='ArgumentParser')
    parser.add_argument('-data', type=str, default="river_1001_full",
                        help='data dir for processing')
    parser.add_argument('-checkpoints', nargs='+', type=str, default=[
        'FPN_epoch_200_Dec24_19_15.pth'
    ],

                        help='checkpoints used for making prediction ')
    parser.add_argument('-load_recent', type=lambda x: (str(x).lower() == 'true'), default=False,
                        help='use newest checkpoint')
    parser.add_argument('-aster', type=lambda x: (str(x).lower() == 'true'), default=True,
                        help='ASTER or not')
    parser.add_argument('-target', type=str, default="segmap", choices=['segmap', 'edge'],
                        help='target for model prediction [segmap, edge]')
    parser.add_argument('-mode', type=str, default="WATER",
                        help='landsat data mode')
    parser.add_argument('-landsat_idx', type=str, default="4 5 6 7 8",
                        help='landsat index')
    parser.add_argument('-centerline', type=lambda x: (str(x).lower() == 'true'),
                        default=False, help='get centerline or not')
    parser.add_argument('-test_all', type=lambda x: (str(x).lower() == 'true'),
                        default=True, help='test all files?')
    parser.add_argument('-img_names', type=str, default=[
        # '09KD993_clip.tif',
        '09KD993_small.tif',
        # 'shinjuku-std.tif',
    ],
                        help='data dirs for processing')
    parser.add_argument('-img_rows', type=int, default=224,
                        help='img rows for croping ')
    parser.add_argument('-img_cols', type=int, default=224,
                        help='img cols for croping ')
    parser.add_argument('-border_remain', type=lambda x: (str(x).lower() == 'true'), default=True,
                        help='remain the border or not?')
    parser.add_argument('-batch_size', type=int, default=22,
                        help='batch size for model prediction ')
    parser.add_argument('-cuda', type=lambda x: (str(x).lower() == 'true'), default=True,
                        help='using cuda for optimization')
    args = parser.parse_args()

    main(args)
