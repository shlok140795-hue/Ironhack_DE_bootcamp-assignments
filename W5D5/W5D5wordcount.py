from pyspark.sql import SparkSession  #Used to create a Spark session
import re                             #used for regular expressions to extract words
import os                             #Used to configure environment variables.

os.environ["PYSPARK_PYTHON"] = r"C:\Users\sneha\anaconda3\python.exe"
os.environ["PYSPARK_DRIVER_PYTHON"] = r"C:\Users\sneha\anaconda3\python.exe"


# Step 1: Create Spark session
spark = SparkSession.builder \
    .appName("DiwaliWordCount") \
    .master("local[*]") \
    .getOrCreate()

sc = spark.sparkContext

# Step 2: Read text file as RDD
file1 = sc.textFile("diwali.txt")

# Step 3: Define stop words
stop_words = {
    "the", "is", "a", "an", "and", "are", "was",
    "were", "in", "on", "of", "to", "for", "with",
    "this", "that", "it", "we", "you", "he", "she",
    "they", "i", "am", "be", "as", "at", "by", "from"
}

# Step 4: Extract words and convert to lowercase
words = file1.flatMap(
    lambda line: re.findall(r"\b[a-z]+\b", line.lower())
)

# Step 5: Remove stop words
filtered_words = words.filter(
    lambda word: word not in stop_words
)

# Step 6: Convert words into key-value pairs
word_pairs = filtered_words.map(
    lambda word: (word, 1)
)

# Step 7: Count occurrences
word_counts = word_pairs.reduceByKey(
    lambda x, y: x + y
)

# Step 8: Find top 5 words
top_5 = word_counts.takeOrdered(
    5,
    key=lambda x: (-x[1], x[0])
)

# Step 9: Print results
print("\nTop 5 most frequent words:")

for word, count in top_5:
    print(word, count)

# Step 10: Stop Spark
spark.stop()
