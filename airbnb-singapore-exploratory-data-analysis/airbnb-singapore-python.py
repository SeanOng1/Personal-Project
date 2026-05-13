import openpyxl
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

#Load data from excel file
df_dict = pd.read_excel(r"airbnb-singapore-exploratory-data-analysis\airbnb-singapore-python.xlsx", sheet_name=None, engine='openpyxl')
df_listings, df_countries, df_reviews, df_calendars = df_dict.values()

#Remove duplicate entries & filter out unecessary columns
df_listings.drop_duplicates(inplace=True, ignore_index=False)
df_listings = df_listings.filter(items=['id', 'host_id', 'host_location', 'host_neighbourhood',
       'neighbourhood_cleansed', 'neighbourhood_group_cleansed', 'latitude', 'longitude',
       'property_type', 'room_type', 'accommodates', 'bathrooms_text', 'bedrooms',
       'beds', 'amenities', 'price', 'number_of_reviews', 'review_scores_rating',
       'review_scores_accuracy', 'review_scores_cleanliness', 'review_scores_checkin',
       'review_scores_communication', 'review_scores_location', 'review_scores_value'])

#Extract only the integer value of bathrooms from String text
bathroom_count = []
for i in range(df_listings.shape[0]):
    bathroom_text = df_listings.iloc[i]['bathrooms_text']
    if pd.isna(bathroom_text):
        bathroom_count.append(bathroom_text)
    elif 'half' in bathroom_text.lower():
        bathroom_count.append(0.5)
    else:
        bathroom_count.append(float(bathroom_text.split()[0]))
df_listings.insert(11,'bathrooms',bathroom_count)

#Extract only the bathroom type from String text
bathroom_type = []
for i in range(df_listings.shape[0]):
    bathroom_text = df_listings.iloc[i]['bathrooms_text']
    if pd.isna(bathroom_text):
        bathroom_type.append(bathroom_text)
    elif 'shared' in bathroom_text.lower():
        bathroom_type.append('Shared')
    else:
        bathroom_type.append('Private')
df_listings.insert(12, 'bathroom_type', bathroom_type)

df_listings.drop(columns=['bathrooms_text'], inplace=True)

#Extract only the country from String text
host_country = []
for i in range(df_listings.shape[0]):
    country = df_listings.iloc[i]['host_location']
    if pd.isna(country):
       host_country.append(country)
    else:
        country = country.split(',')[-1].strip()
        if len(country) == 2:
            country = 'United States Of America'
        host_country.append(country)
df_listings.insert(3, 'host_country', host_country)

#Clean data to form consistent values for easier groupby
df_listings['neighbourhood_group'] = df_listings['neighbourhood_group'].apply(lambda x: x.split()[0])
df_listings['property_type'] = df_listings['property_type'].apply(lambda x: x.split('in ')[-1].split('Entire ')[-1].strip())

#Join 2 dataframes
df_listings = df_listings.merge(df_countries, how='left', left_on='host_country', right_on='Country', validate='many_to_one')
df_listings.drop(columns=['Country'], inplace=True)
df_listings.rename(columns={'id':'listing_id', 'neighbourhood_cleansed':'neighbourhood', 'neighbourhood_group_cleansed':'neighbourhood_group', 'Continent':'host_continent'}, inplace=True)
s_pop = df_listings.pop('host_continent')
df_listings.insert(4, 'host_continent', s_pop)

#Add new sheet for combined data
with pd.ExcelWriter(r"airbnb-singapore-exploratory-data-analysis\airbnb-singapore-python.xlsx", mode='a', engine='openpyxl', if_sheet_exists='replace') as writer:
    df_listings.to_excel(writer, sheet_name='final', index=False)

pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)
pd.set_option('display.float_format', lambda x: '%.2f' % x)
df_listings.info()

#Correlation map between individual review score metrics
df_price_reviews = df_listings.filter(items=['price', 'review_scores_rating', 'review_scores_accuracy', 'review_scores_cleanliness',
            'review_scores_checkin', 'review_scores_communication', 'review_scores_location', 'review_scores_value'])
df_price_reviews.describe()
df_price_reviews.corr()
sns.heatmap(df_price_reviews.corr(), annot = True)
plt.rcParams['figure.figsize'] = (20,7)
plt.show()
df_price_reviews.drop(columns='price').boxplot(figsize=(20,10))
plt.show()

#Dataframes with metrics grouped by room type
df_listings.groupby(by='room_type')['listing_id'].count().sort_values(ascending=False)
df_listings['property_type'].unique()
df_listings[df_listings['property_type'].str.lower().str.contains('bungalow', na=False)]
df_listings.groupby(by='room_type')[['review_scores_rating', 'review_scores_accuracy', 'review_scores_cleanliness', 'review_scores_checkin', 'review_scores_communication',
                                     'review_scores_location', 'review_scores_value']].mean().sort_values(by='review_scores_rating', ascending=False)
df_listings.groupby(by=['room_type', 'neighbourhood_group'])['price'].mean().sort_values(ascending=False)
df_listings.groupby('room_type').agg({'price': ['min','max','count'], 'review_scores_rating': ['mean','count']})

#Bar graph to visualise the average price based on neighbourhood group and room type
df_index = df_listings.groupby(by=['room_type', 'neighbourhood_group'])['price'].mean().sort_values(ascending=False)
df_index.sort_index(ascending=[True, False], inplace=True)
df_index = df_index.reset_index()
bar_plot = sns.catplot(x='neighbourhood_group', y='price', hue='room_type', data=df_index, kind='bar')
bar_plot.set_axis_labels('Neighbourhood Group', 'Average Price')
bar_plot.set_titles('Average Price Per Neighbourhood Group Per Room Type')
plt.show()

#Box plot to visualise the distrbution of review scores
box_plot = sns.boxplot(data=df_listings, x='neighbourhood_group', y ='review_scores_rating', hue='room_type')
box_plot.set_title('Review Scores Rating Per Neighbourhood Group Per Room Type')
box_plot.set_xlabel('Neighbourhood Group')
box_plot.set_ylabel('Review Scores Rating')
plt.show()
