# -*- coding: utf-8 -*-
"""オートエンコーダ.ipynb

Automatically generated by Colaboratory.

Original file is located at
    https://colab.research.google.com/drive/1nkuipCJn-0gVwZnu6q8FqAo6FmQWYqHg
"""

import keras
from keras import layers
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from skimage.metrics import peak_signal_noise_ratio as calculate_psnr_ski
from skimage.metrics import structural_similarity as compare_ssim
np.set_printoptions(threshold=np.inf)
import random

#乱数のシードを設定
random.seed(7)

height, width = 32,32

#オートエンコーダ
def autoencoder_model(encoding_dim):
    input_img = keras.Input(shape=(1024,))
    encoded = layers.Dense(encoding_dim, activation='relu')(input_img)
    decoded = layers.Dense(1024, activation='relu')(encoded)
    autoencoder = keras.Model(input_img, decoded)
    encoder = keras.Model(input_img, encoded)
    decoder_input = keras.Input(shape=(encoding_dim,))
    decoder = keras.Model(decoder_input, autoencoder.layers[-1](decoder_input))
    return autoencoder, encoder, decoder

#パラメータ学習
def train_autoencoder(autoencoder, train_data_A, train_data_B, test_data_A, test_data_B):
    autoencoder.compile(optimizer='adam', loss='mean_squared_error')
    autoencoder.fit(train_data_A, train_data_B, epochs=100, batch_size=64, shuffle=True, validation_data=(test_data_A, test_data_B))   # 学習回数・バッチサイズ
    encoded_imgs = encoder.predict(test_data_A)
    decoded_imgs = decoder.predict(encoded_imgs)
    return decoded_imgs, encoded_imgs

#結果を表示
def display_results(decoded_imgs, test_data, original_imgs):
    n = 33  #土砂崩れ：33、津波・洪水：4に設定してください

    plt.figure(figsize=(20, 120))

    for i in range(n):

        ax = plt.subplot(n, 3, 3 * i + 1)
        plt.imshow(test_data[i].reshape(32, 32)* 255, cmap='gray', vmin=0, vmax=255)
        plt.title(f"ground {i + 1}")
        plt.gray()
        ax.get_xaxis().set_visible(False)
        ax.get_yaxis().set_visible(False)

        ax = plt.subplot(n, 3, 3 * i + 2)
        plt.imshow(original_imgs[i].reshape(32, 32)* 255, cmap='gray', vmin=0, vmax=255)
        plt.title(f"mask {i + 1}")
        plt.gray()
        ax.get_xaxis().set_visible(False)
        ax.get_yaxis().set_visible(False)

        ax = plt.subplot(n, 3, 3 * i + 3)
        plt.imshow(decoded_imgs[i].reshape(32, 32)* 255, cmap='gray', vmin=0, vmax=255)
        plt.title(f"output {i + 1}")
        plt.gray()
        ax.get_xaxis().set_visible(False)
        ax.get_yaxis().set_visible(False)

    plt.show()


#隠れ層の次元
encoding_dim = 32

#オートエンコーダ構築
autoencoder, encoder, decoder = autoencoder_model(encoding_dim)

# データセットの読み込み
test_data_A = pd.read_csv("testdata.csv", header=None)
test_data_B = pd.read_csv("testmask.csv", header=None)
train_data_A = pd.read_csv("traindata.csv", header=None)
train_data_B = pd.read_csv("trainmask.csv", header=None)

# データの前処理と配列への変換
def preprocess_data(data):
    data = data.fillna(0)
    return data.to_numpy() / 255

# 入力データの前処理
X_train = preprocess_data(train_data_A)
X_test = preprocess_data(test_data_A)

# 出力データ（教師データ）の前処理
y_train = preprocess_data(train_data_B)
y_test = preprocess_data(test_data_B)

#パラメータ学習
decoded_imgs, encoded_imgs = train_autoencoder(autoencoder, X_train, y_train, X_test, y_test)

#結果を表示
display_results(decoded_imgs, X_test, y_test)

# データをデータフレームに変換してCSVファイルに保存
df = pd.DataFrame(data_to_save_int.reshape(1, -1), columns=[f'feature_{i}' for i in range(1024)])
df.to_csv(csv_file_path, index=False)

print(f'Data saved to {csv_file_path}')


#各層の重みとバイアスを取得
encoder_weights = autoencoder.layers[1].get_weights()
decoder_weights = autoencoder.layers[2].get_weights()

#各重みとバイアスを配列に格納
encoder_weights_arr = [encoder_weights[0], encoder_weights[1]]
decoder_weights_arr = [decoder_weights[0], decoder_weights[1]]

#エンコーダの重みとバイアス
encoder_weight = encoder_weights[0]
encoder_bias = encoder_weights[1]

#デコーダの重みとバイアス
decoder_weight = decoder_weights[0]
decoder_bias = decoder_weights[1]

max_value = np.max(encoder_weight)
min_value = np.min(encoder_weight)

print("最大:", max_value)
print("最小:", min_value)

bit_length = 16
####################量子化##############################
def list_to_binary(lst, bit_length):
    binary_list = []
    for number in np.nditer(lst):
        binary_representation = decimal_to_binary(number, bit_length)
        binary_list.append(binary_representation)

    binary_array = np.array(binary_list, dtype=np.object)
    binary_array = binary_array.reshape(lst.shape)

    return binary_array

def decimal_to_binary(num, bit_length):
    if abs(num) >= 0.9921875:
        return '0111111111111111'

    if abs(num) <= -0.9921875:
        return '1000000000000000'

    number = num

    sign_bit = '1' if num < 0 else '0'

    if number >= 0:
        if number >= 0.5:
            two_bit = '1'
            number = number - 0.5
        else:
            two_bit = '0'

        if number >= 0.25:
            three_bit = '1'
            number = number - 0.25
        else:
            three_bit = '0'

        if number >= 0.125:
            four_bit = '1'
            number = number - 0.125
        else:
            four_bit = '0'

        if number >= 0.0625:
            five_bit = '1'
            number = number - 0.0625
        else:
            five_bit = '0'

        if number >= 0.03125:
            six_bit = '1'
            number = number - 0.03125
        else:
            six_bit = '0'

        if number >= 0.015625:
            seven_bit = '1'
            number = number - 0.015625
        else:
            seven_bit = '0'

        if number >= 0.0078125:
            eight_bit = '1'
            number = number - 0.0078125
        else:
            eight_bit = '0'

        if number >= 0.00390625:
            nine_bit = '1'
            number = number - 0.00390625
        else:
            nine_bit = '0'

        if number >= 0.001953125:
            ten_bit = '1'
            number = number - 0.001953125
        else:
            ten_bit = '0'

        if number >= 0.0009765625:
            eleven_bit = '1'
            number = number - 0.0009765625
        else:
            eleven_bit = '0'

        if number >= 0.00048828125:
            twelve_bit = '1'
            number = number - 0.00048828125
        else:
            twelve_bit = '0'

        if number >= 0.000244140625:
            thirteen_bit = '1'
            number = number - 0.000244140625
        else:
            thirteen_bit = '0'

        if number >= 1 / 8192:
            fourteen_bit = '1'
            number = number - 1 / 8192
        else:
            fourteen_bit = '0'

        if number >= 1 / 16384:
            fifteen_bit = '1'
            number = number - 1 / 16384
        else:
            fifteen_bit = '0'

        if number >= 1 / 32768:
            sixteen_bit = '1'
            number = number - 1 / 16384
        else:
            sixteen_bit = '0'

    else:
        number = number * -1
        if number >= 0.5:
            two_bit = '0'
            number = number - 0.5
        else:
            two_bit = '1'

        if number >= 0.25:
            three_bit = '0'
            number = number - 0.25
        else:
            three_bit = '1'

        if number >= 0.125:
            four_bit = '0'
            number = number - 0.125
        else:
            four_bit = '1'

        if number >= 0.0625:
            five_bit = '0'
            number = number - 0.0625
        else:
            five_bit = '1'

        if number >= 0.03125:
            six_bit = '0'
            number = number - 0.03125
        else:
            six_bit = '1'

        if number >= 0.015625:
            seven_bit = '0'
            number = number - 0.015625
        else:
            seven_bit = '1'

        if number >= 0.0078125:
            eight_bit = '0'
            number = number - 0.0078125
        else:
            eight_bit = '1'

        if number >= 0.00390625:
            nine_bit = '0'
            number = number - 0.00390625
        else:
            nine_bit = '1'

        if number >= 0.001953125:
            ten_bit = '0'
            number = number - 0.001953125
        else:
            ten_bit = '1'

        if number >= 0.0009765625:
            eleven_bit = '0'
            number = number - 0.0009765625
        else:
            eleven_bit = '1'

        if number >= 0.00048828125:
            twelve_bit = '0'
            number = number - 0.00048828125
        else:
            twelve_bit = '1'

        if number >= 0.000244140625:
            thirteen_bit = '0'
            number = number - 0.000244140625
        else:
            thirteen_bit = '1'

        if number >= 1 / 8192:
            fourteen_bit = '0'
            number = number - 1 / 8192
        else:
            fourteen_bit = '1'

        if number >= 1 / 16384:
            fifteen_bit = '0'
            number = number - 1 / 16384
        else:
            fifteen_bit = '1'

        if number >= 1 / 32768:
            sixteen_bit = '0'
            number = number - 1 / 32768
        else:
            sixteen_bit = '1'

    final_result = sign_bit + two_bit + three_bit + four_bit + five_bit + six_bit + seven_bit + eight_bit + nine_bit + ten_bit + eleven_bit + twelve_bit + thirteen_bit + fourteen_bit + fifteen_bit + sixteen_bit

    if num <= 0:
        increment_binary(final_result)

    return final_result

def increment_binary(binary):
    result = list(binary)

    for i in range(len(result) - 1, -1, -1):
        if result[i] == '0':
            result[i] = '1'
            break
        else:
            result[i] = '0'

    return ''.join(result)

#エンコーダの重みとバイアスを二進数に変換
encoder_weight_binary = list_to_binary(encoder_weight, bit_length)
encoder_bias_binary = list_to_binary(encoder_bias, bit_length)

#デコーダの重みとバイアスを二進数に変換
decoder_weight_binary = list_to_binary(decoder_weight, bit_length)
decoder_bias_binary = list_to_binary(decoder_bias, bit_length)

############################################################
#テストデータの一枚目の画像部分を取得
test_image = X_test[0].reshape((height, width))

#テストデータの一枚目の画像部分をエンコード
encoded_test_image = encoder.predict(X_test[0:1]).reshape((encoding_dim,))

def write_layer_info_to_file(file_path, layer_name, weights, biases, binary_weights, binary_biases, bit_length):
    # 元のファイルへの書き込み
    with open(file_path, 'a') as file:
        file.write(f"{layer_name} Layer:\n")

        num_neurons = weights.shape[1]
        for i in range(num_neurons):
            file.write(f"\n{layer_name} - Neuron {i + 1} - Weight:\n")
            file.write(np.array2string(weights[:, i], precision=8, separator=', ', max_line_width=np.inf))
            file.write(f"\n{layer_name} - Neuron {i + 1} - Weight (Binary):\n")
            file.write(np.array2string(binary_weights[:, i], separator=', ', formatter={'str_kind': lambda x: f"'{x}'"}, max_line_width=np.inf))

        file.write(f"\n{layer_name} - Biases:\n")
        file.write(np.array2string(biases, separator=', ', max_line_width=np.inf))
        file.write(f"\n{layer_name} - Biases (Binary):\n")
        file.write(np.array2string(binary_biases, separator=', ', formatter={'str_kind': lambda x: f"'{x}'"}, max_line_width=np.inf))

        file.write("\n\n")

# ファイルをクリア
with open("autoencoder_info.txt", 'w') as file:
    file.write("")

# エンコーダの情報をファイルに書き込む
write_layer_info_to_file("autoencoder_info.txt", "Encoder", encoder_weight, encoder_bias, encoder_weight_binary, encoder_bias_binary, bit_length)


#テストデータの情報をファイルに書き込む
with open("autoencoder_info.txt", 'a') as file:
    file.write("Original Image:\n")
    file.write(np.array2string(test_image, separator=', ') + '\n\n')

    file.write("Encoded Image:\n")
    file.write(np.array2string(encoded_test_image, separator=', ') + '\n\n')

#デコーダの情報をファイルに書き込む
write_layer_info_to_file("autoencoder_info.txt", "Decoder", decoder_weight, decoder_bias, decoder_weight_binary, decoder_bias_binary, bit_length)

#テストデータの中間層の分布をファイルに書き込む
encoded_test_data = encoder.predict(X_test)
with open("autoencoder_info.txt", 'a') as file:
    file.write("Encoded Layer :\n")
    file.write(np.array2string(encoded_test_data[0], separator=', ') + '\n\n')

#デコードされた最終的な画像データ
decoded_test_data = autoencoder.predict(X_test)
decoded_test_image = decoded_test_data[0].reshape((height, width))

#テストデータの再構成画像をファイルに書き込む
with open("autoencoder_info.txt", 'a') as file:
    file.write("Decoded Image:\n")
    file.write(np.array2string(decoded_test_image, separator=', ') + '\n\n')

############################

### 追加　###
#エンコーダ・デコーダ重みごとに逆に並べる
def write_weights_to_fileA(file_path, layer_name, binary_weights):
    with open(file_path, 'a') as file:
        num_neurons = binary_weights.shape[1]

        for neuron_idx in reversed(range(num_neurons)):
            file.write(f"\n{layer_name} - Neuron {neuron_idx + 1} - Weight (Binary):\n")

            # 重みを逆順にして一列に並べる
            reversed_weights = binary_weights[:, neuron_idx][::-1]
            formatted_binary_weights = "&".join([f'"{bin_val}"' for bin_val in reversed_weights])

#ファイルをクリア
with open("autoencoder_info_updated.txt", 'w') as file:
    file.write("")

#エンコーダの重みをファイルに書き込む
write_weights_to_fileA("autoencoder_info_updated.txt", "Encoder", encoder_weight_binary)

#デコーダの重みをファイルに書き込む
write_weights_to_fileA("autoencoder_info_updated.txt", "Decoder", decoder_weight_binary)

def write_weights_to_fileB(file_path, layer_name, binary_weights):
    with open(file_path, 'a') as file:
        num_neurons = binary_weights.shape[1]

        #すべての二進数を一列に並べるリスト
        all_binary_weights = []

        for neuron_idx in reversed(range(num_neurons)):
            file.write(f"\n{layer_name} - Neuron {neuron_idx + 1} - Weight (Binary):\n")

            #重みを逆順にして一列に並べる
            reversed_weights = binary_weights[:, neuron_idx][::-1]
            formatted_binary_weights = "&".join([f'"{bin_val}"' for bin_val in reversed_weights])

            #ファイルに書き込む
            file.write(formatted_binary_weights + '\n')

            #すべての二進数をリストに追加
            all_binary_weights.extend(reversed_weights)

        #すべての二進数を一列に並べる
        all_formatted_binary_weights = "&".join([f'"{bin_val}"' for bin_val in all_binary_weights])

        #ファイルに書き込む
        file.write(f"\n\nAll {layer_name} Weights (Binary):\n")
        file.write(all_formatted_binary_weights + '\n')

#ファイルをクリア
with open("autoencoder_info_updated.txt", 'w') as file:
    file.write("")

#エンコーダの重みをファイルに書き込む
write_weights_to_fileB("autoencoder_info_updated.txt", "Encoder", encoder_weight_binary)

#デコーダの重みをファイルに書き込む
write_weights_to_fileB("autoencoder_info_updated.txt", "Decoder", decoder_weight_binary)

#ファイルにバイアスの情報を書き込む（更新版）
def write_layer_info_to_file_updated(file_path, layer_name, binary_data, display_order):
    with open(file_path, 'a') as file:
        file.write(f"\n{layer_name} Information:\n")

        # バイナリデータの表示
        file.write(f"\n{layer_name} - Binary Data:\n")
        reversed_binary_data = np.flip(binary_data)  # 配列を逆順にする
        formatted_binary_data = "&".join([f'"{bin_val}"' for bin_val in reversed_binary_data[display_order]])
        file.write(formatted_binary_data)

#エンコーダの情報をファイルに書き込む（更新版）
write_layer_info_to_file_updated("autoencoder_info_updated.txt", "Encoder", encoder_bias_binary, range(encoding_dim)) #ここの数字を中間層の数と同じにする

#デコーダの情報をファイルに書き込む（更新版）
write_layer_info_to_file_updated("autoencoder_info_updated.txt", "Decoder", decoder_bias_binary, range(1024)) #ここの数字を出力次元と同じ数にする

#####テストデータ書き込み
#テストデータの一枚目を取得
test_image = X_test[0]

#ファイルを開いてバイナリ表現を書き込む（修正版）
with open("autoencoder_info_updated.txt", 'a') as file:
    file.write("\nTest Image (Binary):\n")

    #テストデータの一行目
    binary_test_image = "&".join([f'"{bin(int(val))[2:].zfill(8)}"' for val in reversed(test_image.flatten())])
    file.write(f"{binary_test_image}\n")

    file.write("\nEncoded Image (Binary):\n")

    #エンコードされたテストデータの一行目を
    encoded_test_image = encoded_test_data[0].reshape((encoding_dim,))
    binary_encoded_image = "&".join([f'"{bin(int(val))[2:].zfill(8)}"' for val in reversed(encoded_test_image)])
    file.write(f"{binary_encoded_image}\n")

    file.write("\nOutput Image (Binary):\n")

    #デコードされた画像
    binary_output_image = "&".join([f'"{bin(int(val))[2:].zfill(8)}"' for val in reversed(decoded_test_image.flatten())])
    file.write(f"{binary_output_image}\n")

#################################
def write_weights_to_fileC(file_path, layer_name, binary_weights):
    with open(file_path, 'a') as file:
        num_neurons = binary_weights.shape[1]

        # すべての二進数を一列に並べるリスト
        all_binary_weights = []

        for neuron_idx in reversed(range(num_neurons)):
            # 重みを逆順にして一列に並べる
            reversed_weights = binary_weights[:, neuron_idx][::-1]
            formatted_binary_weights = "".join([f'{bin_val}' for bin_val in reversed_weights])

            # すべての二進数をリストに追加
            all_binary_weights.extend(reversed_weights)

        # すべての二進数を一列に並べる
        all_formatted_binary_weights = "".join([f"{bin_val}" for bin_val in all_binary_weights])

        # 256行ごとに改行してファイルに書き込む
        lines = [all_formatted_binary_weights[i:i+512] for i in range(0, len(all_formatted_binary_weights), 512)]

        # 各行の内容をそのままの順番でリストに格納
        lines_list = [line + '\n' for line in lines]

        # リストを逆順にしてファイルに書き込む
        for line in reversed(lines_list):
            file.write(line)

        # プログラムの最後に改行を追加
        file.write('\n')


#ファイルをクリア
with open("autoencoder_weight_bias.txt", 'w') as file:
    file.write("")

#エンコーダの重みをファイルに書き込む
write_weights_to_fileC("autoencoder_weight_bias.txt", "Encoder", encoder_weight_binary)

#デコーダの重みをファイルに書き込む
write_weights_to_fileC("autoencoder_weight_bias.txt", "Decoder", decoder_weight_binary)

def write_layer_info_to_file_updatedC(file_path, layer_name, binary_data, display_order):
    with open(file_path, 'a') as file:
        # バイナリデータの表示
        reversed_binary_data = np.flip(binary_data)  # 配列を逆順にする
        formatted_binary_data = "".join([f'{bin_val}' for bin_val in reversed_binary_data[display_order]])

        # 8文字ごとに分割してリストに追加
        lines_list = [formatted_binary_data[i:i+16] for i in range(0, len(formatted_binary_data), 16)]

        # リストを逆順にしてファイルに書き込む
        for line in reversed(lines_list):
            file.write(line + '\n')

        # プログラムの最後に改行を追加
        file.write('\n')

#エンコーダの情報をファイルに書き込む（更新版）
write_layer_info_to_file_updatedC("autoencoder_weight_bias.txt", "Encoder_bias", encoder_bias_binary, range(encoding_dim)) #ここの数字を中間層の数と同じにする

#デコーダの情報をファイルに書き込む（更新版）
write_layer_info_to_file_updatedC("autoencoder_weight_bias.txt", "Decoder_bias", decoder_bias_binary, range(1024)) #ここの数字を出力次元と同じ数にする


def display_encoded_values(encoded_data):
    n_neurons = encoded_data.shape[1]
    n_samples = encoded_data.shape[0]

    all_values = []

    for sample_idx in range(n_samples):
        print(f"Sample {sample_idx + 1} values:")
        for neuron_idx in range(n_neurons):
            value = encoded_data[sample_idx, neuron_idx]
            all_values.append(value)
            print(f"Neuron {neuron_idx + 1}: {value}")
        print("\n")

    find_min_max_values(all_values)


def find_min_max_values(values):
    if values:
        min_value = min(values)
        max_value = max(values)
        print(f"\nMin: {min_value}")
        print(f"Max: {max_value}")

display_encoded_values(encoded_test_data)

def generate_sub_arrays(data, sub_array_size=4):
    for row in data:
        for i in range(0, len(row), sub_array_size):
            sub_array = row[i:i+sub_array_size]
            yield sub_array

def process_and_write_binary_output(matrix, filename="binary_output.txt", sub_array_size=4, rows_per_group=252):
    result_array = np.array(list(generate_sub_arrays(matrix, sub_array_size)))

    new_order = [3, 2, 1, 0]
    result_array_final = result_array[:, new_order]

    result_binary = np.vectorize(lambda x: np.binary_repr(int(x), width=8), otypes=[str])
    result_array_binary = result_binary(result_array_final)

    with open(filename, "w") as file:
        for i, row in enumerate(result_array_binary):
            binary_string = ''.join(row)
            file.write(binary_string + '\n')
            if (i + 1) % rows_per_group == 0:
                file.write('\n')

output_filename = "testdata_input.txt"
process_and_write_binary_output(X_test, filename=output_filename)

output_filename = "testdata_output.txt"
process_and_write_binary_output(decoded_imgs, filename=output_filename)

import numpy as np

def process_and_write_binary_output(matrix, filename="binary_output.txt", rows_per_group=252):
    result_matrix_reverse = np.fliplr(matrix)

    result_binary = np.vectorize(lambda x: np.binary_repr(int(x), width=8), otypes=[str])
    result_matrix_binary = result_binary(result_matrix_reverse)

    with open(filename, "w") as file:
        for i, row in enumerate(result_matrix_binary):
            binary_string = ''.join(row)
            file.write(binary_string + '\n')

            if (i + 1) % rows_per_group != 0:
                file.write('\n')

output_filename = "testdata_input_reversed.txt"
process_and_write_binary_output(X_test, filename=output_filename)

output_filename = "testdata_output_reversed.txt"
process_and_write_binary_output(decoded_imgs, filename=output_filename)