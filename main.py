import numpy as np
from pprint import pprint

def main():
    """
    main function to generate two different arrays and perform matrix multiplication
    """

    # 1. Create the arrays
    arr1 = np.random.randint(0, 10, (3, 4))
    arr2 = np.random.rand(4, 3)

    # 2. Print labels and data separately for pprint
    print(f'Array1 with shape {arr1.shape}:')
    pprint(arr1)

    print(f'\nArray2 with shape {arr2.shape}:')
    pprint(arr2)

    # 3. Matrix Multiplication
    arr3 = arr1 @ arr2
    print("\nMultiply Both Array (Result):")
    print(f"Shape of resulting matrix multiplication is {arr3.shape}")
    pprint(arr3)

if __name__ == "__main__":
    main()
