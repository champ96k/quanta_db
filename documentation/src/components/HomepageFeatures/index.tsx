import type { ReactNode } from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  emoji: string;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'High Performance',
    emoji: '🚀',
    description: (
      <>
        QuantaDB is designed for speed and efficiency, providing fast data access and processing.
      </>
    ),
  },
  {
    title: 'Scalable Architecture',
    emoji: '📈',
    description: (
      <>
        Scale your database seamlessly to handle growing amounts of data and user traffic.
      </>
    ),
  },
  {
    title: 'Flexible Data Model',
    emoji: '🧩',
    description: (
      <>
        QuantaDB supports a flexible data model, allowing you to adapt to changing data structures easily.
      </>
    ),
  },
  {
    title: 'Reliable and Durable',
    emoji: '🔒',
    description: (
      <>
        Ensuring data safety and availability with built-in reliability and durability features.
      </>
    ),
  },
  {
    title: 'Easy Integration',
    emoji: '🔌',
    description: (
      <>
        Integrate QuantaDB effortlessly with your existing applications and workflows.
      </>
    ),
  },
  {
    title: 'Powerful Query Engine',
    emoji: '⚙️',
    description: (
      <>
        Utilize a powerful query engine for efficient data retrieval, filtering, and sorting.
      </>
    ),
  },
];

function Feature({ title, emoji, description }: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <span className={styles.featureEmoji} role="img" aria-label={title + ' icon'}>{emoji}</span>
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
